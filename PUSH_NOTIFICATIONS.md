# Push Notifications Setup Guide

This guide explains how to configure Apple Push Notification service (APNs) for the Secure Messaging apps.

## Overview

Push notifications alert users when they receive new messages. The flow is:

1. User receives message → Supabase database trigger
2. Backend service detects new message
3. Backend sends push notification via APNs
4. iOS device receives notification and wakes app

## Prerequisites

- Apple Developer Account (paid)
- Access to both ParentApp and ProviderApp code
- Backend server or serverless function capability

## Part 1: APNs Configuration

### 1. Create APNs Authentication Key

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Keys** from the left sidebar
4. Click **+** to create a new key
5. Name it "Secure Messaging APNs Key"
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** → **Register**
8. **Download the .p8 file** (you can only download once!)
9. Note the **Key ID** and **Team ID**

### 2. Configure App IDs

Both app IDs must have Push Notifications enabled:

1. Go to **Identifiers** in Apple Developer Portal
2. Select `com.secure.messaging.parent`
3. Ensure **Push Notifications** is checked
4. Click **Save**
5. Repeat for `com.secure.messaging.provider`

### 3. Update Xcode Projects

Both projects already have push notification entitlements configured. Verify in Xcode:

1. Open project
2. Select target → **Signing & Capabilities**
3. Ensure **Push Notifications** capability is present
4. Ensure **Background Modes** → **Remote notifications** is checked

## Part 2: Device Token Registration

The apps already request notification permissions and register for remote notifications. When a device token is received, it needs to be sent to Supabase.

### Update App Delegate Handling

Add to **ParentAppApp.swift** (and **ProviderAppApp.swift**):

```swift
import SwiftUI
import SharedMessaging
import UserNotifications

@main
struct ParentAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel(userType: .parent)

    init() {
        SupabaseClient.shared.configure(
            supabaseURL: "YOUR_SUPABASE_URL",
            supabaseKey: "YOUR_SUPABASE_ANON_KEY"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token: \(token)")

        // Save token to Supabase
        Task {
            do {
                guard let userId = try await SupabaseClient.shared.currentUserId(),
                      let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
                    return
                }

                // Update device keys with APNs token
                if var keys = try await SupabaseClient.shared.fetchDeviceKeys(
                    userId: userId,
                    deviceId: deviceId
                ) {
                    // Update with token
                    // Note: This requires adding an update method to SupabaseClient
                    print("TODO: Update device token in database")
                }
            } catch {
                print("Error saving device token: \(error)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Extract conversation ID and navigate to chat
        if let conversationId = userInfo["conversation_id"] as? String {
            print("Open conversation: \(conversationId)")
            // TODO: Navigate to ChatView for this conversation
        }

        completionHandler()
    }
}
```

## Part 3: Backend Push Service

You need a backend service to send push notifications when new messages arrive. Here are options:

### Option 1: Supabase Edge Function (Recommended)

Create a Supabase Edge Function that triggers on new message inserts:

**supabase/functions/send-push-notification/index.ts:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get("SUPABASE_URL")!
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const apnsKeyId = Deno.env.get("APNS_KEY_ID")!
const apnsTeamId = Deno.env.get("APNS_TEAM_ID")!
const apnsKey = Deno.env.get("APNS_KEY")! // Your .p8 key content

serve(async (req) => {
  const { record } = await req.json()
  const message = record

  const supabase = createClient(supabaseUrl, supabaseKey)

  // Get recipient's device tokens
  const { data: devices } = await supabase
    .from("device_keys")
    .select("apns_token")
    .eq("user_id", message.recipient_id)

  if (!devices || devices.length === 0) {
    return new Response("No devices found", { status: 200 })
  }

  // Get sender info for notification
  const { data: sender } = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", message.sender_id)
    .single()

  // Send APNs notification to each device
  for (const device of devices) {
    if (!device.apns_token) continue

    await sendAPNs({
      deviceToken: device.apns_token,
      payload: {
        aps: {
          alert: {
            title: sender?.full_name || "New Message",
            body: "You have a new encrypted message",
          },
          sound: "default",
          badge: 1,
        },
        conversation_id: message.conversation_id,
      },
    })
  }

  return new Response("OK", { status: 200 })
})

async function sendAPNs(options: { deviceToken: string; payload: any }) {
  // Implementation using node-apn or direct HTTP/2 to APNs
  // This is a simplified example - you'll need to implement JWT signing
  // and HTTP/2 request to api.push.apple.com

  const jwt = createAPNsJWT(apnsKeyId, apnsTeamId, apnsKey)

  const response = await fetch(
    `https://api.push.apple.com/3/device/${options.deviceToken}`,
    {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": "com.secure.messaging.parent", // or provider
        "apns-push-type": "alert",
      },
      body: JSON.stringify(options.payload),
    }
  )

  return response
}

function createAPNsJWT(keyId: string, teamId: string, privateKey: string): string {
  // Implement JWT creation for APNs
  // Use a JWT library to sign with ES256 algorithm
  // See: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns
  return "jwt_token"
}
```

### Option 2: Database Webhook

Configure a database webhook in Supabase:

1. Go to **Database** → **Webhooks**
2. Create webhook for `public.messages` table on INSERT
3. Point to your backend endpoint
4. Backend receives webhook and sends APNs notification

### Option 3: Realtime Listener

Run a Node.js service that subscribes to Supabase Realtime:

```javascript
const { createClient } = require('@supabase/supabase-js')
const apn = require('apn')

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

// Configure APNs
const apnProvider = new apn.Provider({
  token: {
    key: './APNsKey.p8',
    keyId: 'YOUR_KEY_ID',
    teamId: 'YOUR_TEAM_ID'
  },
  production: false // Set to true for production
})

// Subscribe to new messages
supabase
  .channel('messages')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'messages' },
    async (payload) => {
      const message = payload.new

      // Fetch recipient devices
      const { data: devices } = await supabase
        .from('device_keys')
        .select('apns_token')
        .eq('user_id', message.recipient_id)

      // Send push to each device
      for (const device of devices) {
        const notification = new apn.Notification({
          alert: 'You have a new message',
          sound: 'default',
          topic: 'com.secure.messaging.parent',
          payload: { conversation_id: message.conversation_id }
        })

        await apnProvider.send(notification, device.apns_token)
      }
    }
  )
  .subscribe()
```

## Part 4: Testing

### Test in Development

1. Build and run on a **physical device** (push doesn't work on simulator)
2. Check Xcode console for device token
3. Trigger a test notification using a tool like [Knuff](https://github.com/KnuffApp/Knuff) or [Pusher](https://github.com/noodlewerk/NWPusher)

### Test Payload

```json
{
  "aps": {
    "alert": {
      "title": "Dr. Smith",
      "body": "You have a new message"
    },
    "sound": "default",
    "badge": 1
  },
  "conversation_id": "uuid-of-conversation"
}
```

### Production Testing

1. Change `aps-environment` to `production` in entitlements
2. Archive and upload to TestFlight
3. Install via TestFlight
4. Test notifications

## Security Considerations

1. **Never expose APNs key**: Store in environment variables, not in code
2. **Validate webhook signatures**: If using webhooks, verify they're from Supabase
3. **Rate limiting**: Prevent notification spam
4. **User preferences**: Allow users to disable notifications
5. **Silent notifications**: Consider using silent push for encrypted message sync

## Troubleshooting

### No Device Token

- Check that app has notification permissions
- Verify entitlements are correct
- Ensure running on physical device
- Check that App ID has Push Notifications enabled

### Notifications Not Received

- Verify APNs key is correct and not expired
- Check device token is saved to database
- Ensure topic matches bundle identifier
- Check APNs response for errors
- Verify device has internet connection

### Invalid Token Error

- Device token may have changed (user reinstalled app)
- Implement feedback service to remove invalid tokens
- Update tokens periodically

## Additional Resources

- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [APNs Provider API](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server)
- [node-apn Library](https://github.com/node-apn/node-apn)

---

**Note**: Push notifications require additional backend infrastructure. The iOS apps are configured to receive notifications, but you must implement the sending service based on your infrastructure preferences.
