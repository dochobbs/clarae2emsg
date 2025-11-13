# Secure Messaging System for iOS

End-to-end encrypted messaging system between Parent and Provider iOS apps using Signal Protocol, Supabase, and SwiftUI.

## 🔒 Security Features

- **Signal Protocol Encryption**: Industry-standard E2E encryption using X25519 key exchange and XChaCha20-Poly1305 AEAD
- **Zero-Knowledge Architecture**: Messages are encrypted on-device; server never sees plaintext
- **Secure Key Storage**: Encryption keys stored in iOS Keychain
- **Perfect Forward Secrecy**: Each conversation has unique session keys
- **Apple Sign-In**: Secure authentication with Apple's privacy-focused sign-in

## 📦 Project Structure

```
dochobbs/
├── SharedMessaging/              # Shared Swift Package
│   ├── Package.swift
│   └── Sources/SharedMessaging/
│       ├── Models/               # Data models (Profile, Message, Conversation, etc.)
│       ├── Crypto/               # Encryption (EncryptionService, KeychainStorage)
│       ├── Services/             # Business logic (MessagingService, SupabaseClient)
│       └── SharedMessaging.swift
│
├── ParentApp/                    # Parent iOS App
│   └── ParentApp.xcodeproj
│       └── ParentApp/
│           ├── ParentAppApp.swift
│           ├── ContentView.swift
│           ├── ViewModels/
│           │   └── AuthViewModel.swift
│           └── Views/
│               ├── ConversationListView.swift
│               └── ChatView.swift
│
├── ProviderApp/                  # Provider iOS App
│   └── ProviderApp.xcodeproj
│       └── ProviderApp/
│           ├── ProviderAppApp.swift
│           ├── ContentView.swift
│           ├── ViewModels/
│           │   └── AuthViewModel.swift
│           └── Views/
│               ├── ConversationListView.swift
│               └── ChatView.swift
│
└── supabase/
    └── schema.sql                # Database schema
```

## 🚀 Setup Instructions

### 1. Prerequisites

- macOS 14+ with Xcode 15+
- iOS 16+ target devices
- Supabase account
- Apple Developer Account (for App IDs and capabilities)

### 2. Supabase Setup

#### Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create a new project
2. Note your **Project URL** and **Anon Key** from Settings → API

#### Run Database Migration

1. Open the SQL Editor in your Supabase dashboard
2. Copy the contents of `supabase/schema.sql`
3. Paste and execute the SQL to create all tables, indexes, RLS policies, and functions

#### Configure Authentication

1. Go to Authentication → Providers
2. Enable **Apple** provider
3. Follow Supabase's guide to configure Apple Sign-In:
   - Create Service ID in Apple Developer Portal
   - Add authorized domains
   - Configure keys

### 3. iOS Project Setup

#### Configure Supabase Credentials

Both apps need your Supabase credentials:

**ParentApp/ParentApp/ParentAppApp.swift:**
```swift
SupabaseClient.shared.configure(
    supabaseURL: "YOUR_SUPABASE_URL",      // e.g., https://xxx.supabase.co
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"  // Your anon/public key
)
```

**ProviderApp/ProviderApp/ProviderAppApp.swift:**
```swift
SupabaseClient.shared.configure(
    supabaseURL: "YOUR_SUPABASE_URL",
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

#### Link SharedMessaging Package

For both Xcode projects:

1. Open `ParentApp.xcodeproj` (or `ProviderApp.xcodeproj`)
2. Select project in navigator
3. Select target → General → Frameworks, Libraries, and Embedded Content
4. Click "+" → Add Local → Select `SharedMessaging` folder
5. Build the project to resolve dependencies

### 4. Apple Developer Configuration

#### Create App IDs

Create two App IDs in [Apple Developer Portal](https://developer.apple.com):

1. **ParentApp**: `com.secure.messaging.parent`
   - Enable capabilities:
     - Sign in with Apple
     - Push Notifications
     - Keychain Sharing

2. **ProviderApp**: `com.secure.messaging.provider`
   - Enable capabilities:
     - Sign in with Apple
     - Push Notifications
     - Keychain Sharing

#### Configure Push Notifications

See [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md) for detailed setup.

### 5. Build and Run

1. Open `ParentApp.xcodeproj` in Xcode
2. Select a simulator or device
3. Update the Development Team in Signing & Capabilities
4. Build and run (⌘R)

Repeat for `ProviderApp.xcodeproj`

## 🔐 How Encryption Works

### Key Generation (First Launch)

1. User signs in with Apple
2. App generates:
   - **Identity Key Pair** (long-term, X25519)
   - **Signed Pre-Key Pair** (medium-term, signed by identity key)
   - **One-Time Pre-Keys** (100 ephemeral keys)
3. Public keys uploaded to Supabase
4. Private keys stored in iOS Keychain

### Message Encryption Flow

```
Sender                          Supabase                       Recipient
  │                                │                               │
  │ 1. Fetch recipient's keys     │                               │
  ├───────────────────────────────>│                               │
  │                                │                               │
  │ 2. Perform X3DH key exchange  │                               │
  │    (compute shared secret)     │                               │
  │                                │                               │
  │ 3. Encrypt message with        │                               │
  │    session key (ChaCha20)      │                               │
  │                                │                               │
  │ 4. Upload encrypted message    │                               │
  ├───────────────────────────────>│                               │
  │                                │                               │
  │                                │  5. Real-time notification    │
  │                                ├──────────────────────────────>│
  │                                │                               │
  │                                │  6. Fetch encrypted message   │
  │                                │<──────────────────────────────┤
  │                                │                               │
  │                                │  7. Decrypt with session key  │
  │                                │     (derived from X3DH)       │
  │                                │                               │
```

### Encryption Algorithm

- **Key Exchange**: X3DH (Extended Triple Diffie-Hellman)
- **Encryption**: XChaCha20-Poly1305 AEAD
- **Key Derivation**: BLAKE2b
- **Key Storage**: iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`

## 📱 Features

### Authentication
- ✅ Apple Sign-In
- ✅ Profile creation (name, email, user type)
- ✅ Automatic encryption key generation

### Messaging
- ✅ Real-time E2E encrypted messaging
- ✅ Message status indicators (sent, delivered, read)
- ✅ Conversation list with unread counts
- ✅ SwiftUI interface
- ✅ Pull-to-refresh

### Security
- ✅ Signal Protocol encryption
- ✅ Secure key storage in Keychain
- ✅ Row-Level Security in database
- ✅ No plaintext on server

### Push Notifications (Setup Required)
- ⚠️ APNs certificate/key configuration needed
- ⚠️ Server-side push notification service needed
- See [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md)

## 🔧 Dependencies

### SharedMessaging Package
- `supabase-swift` (2.0+) - Database and auth
- `swift-sodium` (0.9+) - Cryptography (libsodium)

### iOS Requirements
- iOS 16.0+
- Swift 5.9+
- Xcode 15.0+

## 🏗️ Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                              │
├─────────────────────────────────────────────────────────────┤
│  SwiftUI Views                                               │
│    │                                                          │
│    ├─ AuthViewModel (Authentication)                         │
│    ├─ ConversationListViewModel (List conversations)         │
│    └─ ChatViewModel (Send/receive messages)                  │
│         │                                                     │
│         ▼                                                     │
│  MessagingService (High-level messaging logic)               │
│         │                                                     │
│         ├─ SupabaseClient (Database operations)              │
│         ├─ EncryptionService (Crypto operations)             │
│         └─ KeychainStorage (Secure key storage)              │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS + WebSocket
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Supabase                               │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL Database                                         │
│    ├─ profiles (user accounts)                              │
│    ├─ device_keys (public encryption keys)                  │
│    ├─ conversations (parent-provider pairs)                 │
│    ├─ messages (encrypted messages)                         │
│    └─ conversation_metadata (unread counts, etc.)           │
│                                                              │
│  Realtime (WebSocket subscriptions)                         │
│  Row Level Security (RLS policies)                          │
│  Authentication (Apple Sign-In)                             │
└─────────────────────────────────────────────────────────────┘
```

## 🧪 Testing

### Create Test Users

1. Run ParentApp, sign in with Apple, create profile as "Parent"
2. Run ProviderApp, sign in with Apple (different Apple ID), create profile as "Provider"
3. In ParentApp, tap "New Message", select the provider
4. Send encrypted messages between apps!

### Verify Encryption

1. Send a message from ParentApp to ProviderApp
2. Open Supabase dashboard → Table Editor → messages
3. View the `encrypted_content` column - it should be base64-encoded ciphertext
4. You should NOT be able to read the message content in the database

## 🚨 Security Considerations

### Production Checklist

- [ ] Rotate Supabase API keys regularly
- [ ] Enable rate limiting on Supabase
- [ ] Implement certificate pinning
- [ ] Add additional one-time pre-keys periodically
- [ ] Implement key rotation policy
- [ ] Add biometric authentication
- [ ] Enable advanced RLS policies
- [ ] Monitor for suspicious activity
- [ ] Implement message deletion
- [ ] Add screenshot prevention in sensitive views

### Known Limitations

1. **Push Notifications**: Not fully implemented (requires APNs setup and backend service)
2. **Multi-Device**: Each device has separate keys (Signal Protocol supports this, but requires additional implementation)
3. **Group Messaging**: Currently supports 1:1 only
4. **Media Messages**: Text only (can be extended to images/files)
5. **Message History**: No cloud backup (encrypted keys stored only on device)

## 📚 Additional Resources

- [Signal Protocol Documentation](https://signal.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [libsodium Documentation](https://doc.libsodium.org/)
- [Apple Sign-In Documentation](https://developer.apple.com/sign-in-with-apple/)

## 📄 License

This is a sample implementation for educational purposes. Review and test thoroughly before using in production.

## 🤝 Support

For issues or questions:
1. Check the documentation files in this repository
2. Review Supabase and Swift package documentation
3. Test encryption flow in a debugger
4. Verify database RLS policies are working correctly

---

Built with ❤️ using SwiftUI, Supabase, and Signal Protocol
