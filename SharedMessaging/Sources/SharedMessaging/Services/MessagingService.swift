import Foundation
import Combine

/// High-level messaging service that handles E2E encryption and message sending/receiving
public class MessagingService: ObservableObject {
    private let supabase: SupabaseClient
    private let encryption: EncryptionService
    private let keychain: KeychainStorage
    private let deviceId: String

    @Published public var conversations: [ConversationWithMetadata] = []

    public init(
        supabase: SupabaseClient = .shared,
        deviceId: String
    ) {
        self.supabase = supabase
        self.encryption = EncryptionService()
        self.keychain = KeychainStorage(service: "com.secure.messaging")
        self.deviceId = deviceId
    }

    // MARK: - Setup

    /// Initialize encryption keys for the current device
    public func initializeKeys(for userId: UUID) async throws {
        // Check if keys already exist
        if let _ = try? keychain.loadKeyPair(forKey: "identity_key") {
            // Keys already exist
            return
        }

        // Generate new keys
        guard let identityKey = encryption.generateIdentityKeyPair() else {
            throw MessagingError.keyGenerationFailed
        }

        guard let signedPreKey = encryption.generateSignedPreKeyPair(
            identitySecretKey: identityKey.secretKey
        ) else {
            throw MessagingError.keyGenerationFailed
        }

        let oneTimePreKeys = encryption.generateOneTimePreKeys(count: 100)

        // Store keys in keychain
        try keychain.saveKeyPair(identityKey, forKey: "identity_key")
        try keychain.saveKeyPair(
            KeyPair(publicKey: signedPreKey.publicKey, secretKey: signedPreKey.secretKey),
            forKey: "signed_prekey"
        )

        // Upload public keys to server
        let oneTimeKeysJson = try JSONEncoder().encode(
            oneTimePreKeys.map { encryption.encodeKeyToBase64($0.publicKey) }
        )

        let deviceKeys = DeviceKeys(
            userId: userId,
            deviceId: deviceId,
            identityKey: encryption.encodeKeyToBase64(identityKey.publicKey),
            signedPrekey: encryption.encodeKeyToBase64(signedPreKey.publicKey),
            signedPrekeySignature: encryption.encodeKeyToBase64(signedPreKey.signature),
            oneTimePrekeys: String(data: oneTimeKeysJson, encoding: .utf8) ?? "[]"
        )

        try await supabase.saveDeviceKeys(deviceKeys)
    }

    // MARK: - Conversations

    public func fetchConversations(for userId: UUID, userType: UserType) async throws -> [ConversationWithMetadata] {
        let conversations = try await supabase.fetchConversations(for: userId)

        var result: [ConversationWithMetadata] = []

        for conversation in conversations {
            let otherUserId = conversation.otherUserId(currentUserId: userId)
            let otherUser = try await supabase.fetchProfile(userId: otherUserId)
            let metadata = try? await supabase.fetchConversationMetadata(conversationId: conversation.id)

            result.append(ConversationWithMetadata(
                conversation: conversation,
                metadata: metadata,
                otherUser: otherUser
            ))
        }

        self.conversations = result
        return result
    }

    public func createConversation(parentId: UUID, providerId: UUID) async throws -> Conversation {
        return try await supabase.createConversation(parentId: parentId, providerId: providerId)
    }

    // MARK: - Messaging

    public func sendMessage(
        content: String,
        conversationId: UUID,
        senderId: UUID,
        recipientId: UUID
    ) async throws -> Message {
        // Get or establish session key
        let sessionKey = try await getOrCreateSessionKey(
            conversationId: conversationId,
            senderId: senderId,
            recipientId: recipientId
        )

        // Encrypt message
        guard let encryptedMessage = encryption.encryptMessage(content, sessionKey: sessionKey) else {
            throw MessagingError.encryptionFailed
        }

        // Get recipient's device (for now, use first device)
        let recipientDevices = try await supabase.fetchUserDeviceKeys(userId: recipientId)
        guard let recipientDevice = recipientDevices.first else {
            throw MessagingError.recipientDeviceNotFound
        }

        // Create message
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            recipientId: recipientId,
            encryptedContent: encryption.encodeKeyToBase64(encryptedMessage.ciphertext),
            senderDeviceId: deviceId,
            recipientDeviceId: recipientDevice.deviceId
        )

        // Send to server
        return try await supabase.sendMessage(message)
    }

    public func fetchMessages(conversationId: UUID) async throws -> [DecryptedMessage] {
        let messages = try await supabase.fetchMessages(conversationId: conversationId, limit: 100)

        // Get session key
        guard let sessionKey = try? keychain.loadSessionKey(forConversation: conversationId.uuidString) else {
            // No session key yet, return empty
            return []
        }

        // Decrypt messages
        var decrypted: [DecryptedMessage] = []
        for message in messages {
            if let ciphertext = encryption.decodeKeyFromBase64(message.encryptedContent),
               let plaintext = encryption.decryptMessage(
                EncryptedMessage(ciphertext: ciphertext),
                sessionKey: sessionKey
               ) {
                decrypted.append(DecryptedMessage(from: message, decryptedContent: plaintext))
            }
        }

        return decrypted
    }

    public func markMessageAsRead(messageId: UUID) async throws {
        try await supabase.updateMessageStatus(messageId: messageId, status: .read)
    }

    public func markMessageAsDelivered(messageId: UUID) async throws {
        try await supabase.updateMessageStatus(messageId: messageId, status: .delivered)
    }

    public func resetUnreadCount(conversationId: UUID, userId: UUID) async throws {
        try await supabase.resetUnreadCount(conversationId: conversationId, userId: userId)
    }

    // MARK: - Session Management

    private func getOrCreateSessionKey(
        conversationId: UUID,
        senderId: UUID,
        recipientId: UUID
    ) async throws -> Data {
        // Try to load existing session key
        if let existingKey = try? keychain.loadSessionKey(forConversation: conversationId.uuidString) {
            return existingKey
        }

        // Create new session
        guard let identityKey = try? keychain.loadKeyPair(forKey: "identity_key"),
              let senderEphemeralKey = encryption.generateIdentityKeyPair() else {
            throw MessagingError.keyGenerationFailed
        }

        // Get recipient's keys
        let recipientDevices = try await supabase.fetchUserDeviceKeys(userId: recipientId)
        guard let recipientDevice = recipientDevices.first else {
            throw MessagingError.recipientDeviceNotFound
        }

        guard let recipientIdentityKey = encryption.decodeKeyFromBase64(recipientDevice.identityKey),
              let recipientSignedPreKey = encryption.decodeKeyFromBase64(recipientDevice.signedPrekey) else {
            throw MessagingError.invalidRecipientKeys
        }

        // Perform X3DH key exchange
        guard let sessionKeys = encryption.initiateSession(
            senderIdentityKey: identityKey,
            senderEphemeralKey: senderEphemeralKey,
            recipientIdentityKey: recipientIdentityKey,
            recipientSignedPreKey: recipientSignedPreKey,
            recipientOneTimePreKey: nil
        ) else {
            throw MessagingError.keyExchangeFailed
        }

        // Store session key
        try keychain.saveSessionKey(
            sessionKeys.encryptionKey,
            forConversation: conversationId.uuidString
        )

        return sessionKeys.encryptionKey
    }

    // MARK: - Real-time

    public func subscribeToConversation(
        conversationId: UUID,
        onNewMessage: @escaping (DecryptedMessage) -> Void
    ) async throws {
        try await supabase.subscribeToMessages(conversationId: conversationId) { [weak self] message in
            guard let self = self else { return }

            // Decrypt message
            if let sessionKey = try? self.keychain.loadSessionKey(forConversation: conversationId.uuidString),
               let ciphertext = self.encryption.decodeKeyFromBase64(message.encryptedContent),
               let plaintext = self.encryption.decryptMessage(
                EncryptedMessage(ciphertext: ciphertext),
                sessionKey: sessionKey
               ) {
                let decrypted = DecryptedMessage(from: message, decryptedContent: plaintext)
                onNewMessage(decrypted)
            }
        }
    }
}

// MARK: - Errors

public enum MessagingError: Error, LocalizedError {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case keyExchangeFailed
    case recipientDeviceNotFound
    case invalidRecipientKeys
    case sessionNotFound

    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption keys"
        case .encryptionFailed:
            return "Failed to encrypt message"
        case .decryptionFailed:
            return "Failed to decrypt message"
        case .keyExchangeFailed:
            return "Failed to exchange keys"
        case .recipientDeviceNotFound:
            return "Recipient device not found"
        case .invalidRecipientKeys:
            return "Invalid recipient keys"
        case .sessionNotFound:
            return "Session not found"
        }
    }
}
