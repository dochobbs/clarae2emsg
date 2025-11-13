# Quick Start Guide

Get the secure messaging system up and running in 15 minutes!

## Prerequisites

- [ ] Xcode 15+ installed
- [ ] Supabase account (free tier works)
- [ ] Apple Developer account (for Sign in with Apple)

## Step 1: Supabase Setup (5 minutes)

### 1.1 Create Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Choose organization, name, and region
4. Wait for database to initialize (~2 mins)

### 1.2 Get Credentials

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### 1.3 Create Database Tables

1. Go to **SQL Editor**
2. Open `supabase/schema.sql` from this project
3. Copy and paste entire contents
4. Click **Run**
5. Verify tables created: **Database** → **Tables** (should see 5 tables)

### 1.4 Configure Apple Sign-In

1. Go to **Authentication** → **Providers**
2. Find **Apple** and click configure
3. Follow Supabase instructions to:
   - Create Service ID in Apple Developer Portal
   - Configure redirect URLs
   - Add keys

## Step 2: iOS Project Setup (5 minutes)

### 2.1 Configure Supabase Credentials

**ParentApp/ParentApp/ParentAppApp.swift** (line ~12):
```swift
SupabaseClient.shared.configure(
    supabaseURL: "YOUR_SUPABASE_URL",     // ← Paste Project URL here
    supabaseKey: "YOUR_SUPABASE_ANON_KEY" // ← Paste anon key here
)
```

**ProviderApp/ProviderApp/ProviderAppApp.swift** (line ~12):
```swift
SupabaseClient.shared.configure(
    supabaseURL: "YOUR_SUPABASE_URL",     // ← Same URL
    supabaseKey: "YOUR_SUPABASE_ANON_KEY" // ← Same key
)
```

### 2.2 Open Projects

Open both projects in Xcode:
```bash
open ParentApp/ParentApp.xcodeproj
open ProviderApp/ProviderApp.xcodeproj
```

### 2.3 Link SharedMessaging Package

For **ParentApp**:
1. File → Add Package Dependencies
2. Click "Add Local..."
3. Navigate to and select `SharedMessaging` folder
4. Click "Add Package"

Repeat for **ProviderApp**

### 2.4 Update Signing

For both projects:
1. Select project in navigator
2. Select target
3. **Signing & Capabilities** tab
4. Update **Team** dropdown to your Apple Developer team
5. Change **Bundle Identifier** if needed (must be unique)

## Step 3: Test It! (5 minutes)

### 3.1 Run ParentApp

1. Select **ParentApp** scheme
2. Select iOS Simulator (iPhone 15)
3. Press **⌘R** to build and run
4. Tap **Sign in with Apple**
5. Sign in with your Apple ID
6. Fill in profile (Full Name, Email)
7. App should show empty message list

### 3.2 Run ProviderApp

1. Select **ProviderApp** scheme
2. Select **different** iOS Simulator (iPhone 15 Pro)
3. Press **⌘R** to build and run
4. Sign in with **different** Apple ID
5. Fill in profile
6. App should show empty message list

### 3.3 Send Messages

In **ParentApp**:
1. Tap **+** (New Message)
2. Select the provider you just created
3. Type a message and send
4. Message should appear encrypted in chat

In **ProviderApp**:
1. Conversation should appear in list
2. Tap to open
3. Should see decrypted message!
4. Reply with a message

### 3.4 Verify Encryption

1. Open Supabase dashboard
2. Go to **Table Editor** → **messages**
3. Look at `encrypted_content` column
4. Should see base64 gibberish (not readable text!)

## Troubleshooting

### "Cannot find SharedMessaging"

- Make sure you added the package as a **local** package
- Try: File → Packages → Reset Package Caches
- Clean build: ⌘K, then rebuild: ⌘B

### "Supabase client not configured"

- Double-check you updated BOTH app files with correct URL and key
- Make sure strings are in quotes
- Rebuild project

### "Sign in with Apple failed"

- Ensure you configured Apple provider in Supabase
- Check Supabase logs: **Authentication** → **Logs**
- Verify Service ID is correct

### No messages appearing

- Check both simulators are running
- Verify internet connection
- Check Supabase logs: **Logs** tab
- Try restarting the app

### Build errors about missing types

- Ensure Swift Package dependencies are resolved
- Try: File → Packages → Update to Latest Package Versions
- Check Package.swift has correct versions

## Next Steps

Now that you have it working:

1. ✅ Test on real devices (simulators don't support push notifications)
2. ✅ Set up push notifications (see [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md))
3. ✅ Customize UI colors and branding
4. ✅ Add more features (images, typing indicators, etc.)
5. ✅ Review security checklist in [SECURE_MESSAGING_README.md](./SECURE_MESSAGING_README.md)

## Support

- 📖 Full documentation: [SECURE_MESSAGING_README.md](./SECURE_MESSAGING_README.md)
- 🔔 Push setup: [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md)
- 🗄️ Database schema: `supabase/schema.sql`
- 🔐 Encryption code: `SharedMessaging/Sources/SharedMessaging/Crypto/`

---

**Stuck?** Double-check each step carefully. Most issues are due to:
- Missing Supabase credentials
- Package not linked properly
- Wrong bundle identifier/team

Happy secure messaging! 🔒💬
