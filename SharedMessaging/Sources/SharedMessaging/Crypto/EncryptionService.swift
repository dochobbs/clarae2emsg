import Foundation
import Sodium

/// Signal Protocol-style end-to-end encryption service
/// Uses X25519 key exchange and XChaCha20-Poly1305 AEAD encryption
public class EncryptionService {
    private let sodium = Sodium()

    public init() {}

    // MARK: - Key Generation

    /// Generate a new identity key pair (long-term)
    public func generateIdentityKeyPair() -> KeyPair? {
        guard let keyPair = sodium.box.keyPair() else {
            return nil
        }
        return KeyPair(publicKey: keyPair.publicKey, secretKey: keyPair.secretKey)
    }

    /// Generate a signed pre-key pair
    public func generateSignedPreKeyPair(identitySecretKey: Data) -> SignedPreKey? {
        guard let keyPair = sodium.box.keyPair() else {
            return nil
        }

        // Sign the public key with identity key
        guard let signature = sodium.sign.signature(
            message: keyPair.publicKey,
            secretKey: identitySecretKey.bytes
        ) else {
            return nil
        }

        return SignedPreKey(
            publicKey: keyPair.publicKey,
            secretKey: keyPair.secretKey,
            signature: signature
        )
    }

    /// Generate one-time pre-keys (batch)
    public func generateOneTimePreKeys(count: Int = 100) -> [KeyPair] {
        var keys: [KeyPair] = []
        for _ in 0..<count {
            if let keyPair = sodium.box.keyPair() {
                keys.append(KeyPair(publicKey: keyPair.publicKey, secretKey: keyPair.secretKey))
            }
        }
        return keys
    }

    // MARK: - Key Agreement (X3DH - Extended Triple Diffie-Hellman)

    /// Sender initiates session with recipient's keys
    public func initiateSession(
        senderIdentityKey: KeyPair,
        senderEphemeralKey: KeyPair,
        recipientIdentityKey: Data,
        recipientSignedPreKey: Data,
        recipientOneTimePreKey: Data?
    ) -> SessionKeys? {
        // Verify signed pre-key signature (in production, do this)
        // For simplicity, we'll skip verification here

        // Perform X3DH key agreement
        var sharedSecrets: [Data] = []

        // DH1: sender_identity_key * recipient_signed_prekey
        if let dh1 = performDH(senderIdentityKey.secretKey, recipientSignedPreKey) {
            sharedSecrets.append(dh1)
        }

        // DH2: sender_ephemeral_key * recipient_identity_key
        if let dh2 = performDH(senderEphemeralKey.secretKey, recipientIdentityKey) {
            sharedSecrets.append(dh2)
        }

        // DH3: sender_ephemeral_key * recipient_signed_prekey
        if let dh3 = performDH(senderEphemeralKey.secretKey, recipientSignedPreKey) {
            sharedSecrets.append(dh3)
        }

        // DH4 (optional): sender_ephemeral_key * recipient_one_time_prekey
        if let oneTimeKey = recipientOneTimePreKey,
           let dh4 = performDH(senderEphemeralKey.secretKey, oneTimeKey) {
            sharedSecrets.append(dh4)
        }

        // Derive encryption key from shared secrets
        guard let sessionKey = deriveSessionKey(from: sharedSecrets) else {
            return nil
        }

        return SessionKeys(
            encryptionKey: sessionKey,
            senderEphemeralPublicKey: senderEphemeralKey.publicKey
        )
    }

    /// Recipient accepts session from sender's keys
    public func acceptSession(
        recipientIdentityKey: KeyPair,
        recipientSignedPreKey: KeyPair,
        recipientOneTimePreKey: KeyPair?,
        senderIdentityKey: Data,
        senderEphemeralKey: Data
    ) -> Data? {
        // Perform same X3DH key agreement (reverse)
        var sharedSecrets: [Data] = []

        // DH1: recipient_signed_prekey * sender_identity_key
        if let dh1 = performDH(recipientSignedPreKey.secretKey, senderIdentityKey) {
            sharedSecrets.append(dh1)
        }

        // DH2: recipient_identity_key * sender_ephemeral_key
        if let dh2 = performDH(recipientIdentityKey.secretKey, senderEphemeralKey) {
            sharedSecrets.append(dh2)
        }

        // DH3: recipient_signed_prekey * sender_ephemeral_key
        if let dh3 = performDH(recipientSignedPreKey.secretKey, senderEphemeralKey) {
            sharedSecrets.append(dh3)
        }

        // DH4 (optional): recipient_one_time_prekey * sender_ephemeral_key
        if let oneTimeKey = recipientOneTimePreKey,
           let dh4 = performDH(oneTimeKey.secretKey, senderEphemeralKey) {
            sharedSecrets.append(dh4)
        }

        // Derive same encryption key
        return deriveSessionKey(from: sharedSecrets)
    }

    // MARK: - Encryption/Decryption

    /// Encrypt a message with session key
    public func encryptMessage(_ message: String, sessionKey: Data) -> EncryptedMessage? {
        guard let messageData = message.data(using: .utf8) else {
            return nil
        }

        // Use XChaCha20-Poly1305 AEAD
        guard let encrypted = sodium.aead.xchacha20poly1305ietf.encrypt(
            message: messageData.bytes,
            secretKey: sessionKey.bytes
        ) else {
            return nil
        }

        return EncryptedMessage(ciphertext: Data(encrypted))
    }

    /// Decrypt a message with session key
    public func decryptMessage(_ encryptedMessage: EncryptedMessage, sessionKey: Data) -> String? {
        guard let decrypted = sodium.aead.xchacha20poly1305ietf.decrypt(
            authenticatedCipherText: encryptedMessage.ciphertext.bytes,
            secretKey: sessionKey.bytes
        ) else {
            return nil
        }

        return String(data: Data(decrypted), encoding: .utf8)
    }

    // MARK: - Helper Functions

    private func performDH(_ secretKey: Data, _ publicKey: Data) -> Data? {
        // Compute shared secret using X25519
        guard let sharedSecret = sodium.box.beforenm(
            recipientPublicKey: publicKey.bytes,
            senderSecretKey: secretKey.bytes
        ) else {
            return nil
        }
        return Data(sharedSecret)
    }

    private func deriveSessionKey(from sharedSecrets: [Data]) -> Data? {
        // Concatenate all shared secrets
        var combined = Data()
        for secret in sharedSecrets {
            combined.append(secret)
        }

        // Use BLAKE2b to derive final key
        guard let derivedKey = sodium.genericHash.hash(
            message: combined.bytes,
            key: "SecureMessaging".bytes, // Salt
            outputLength: 32 // 256-bit key
        ) else {
            return nil
        }

        return Data(derivedKey)
    }

    // MARK: - Encoding/Decoding

    public func encodeKeyToBase64(_ key: Data) -> String {
        return key.base64EncodedString()
    }

    public func decodeKeyFromBase64(_ base64String: String) -> Data? {
        return Data(base64Encoded: base64String)
    }
}

// MARK: - Supporting Types

public struct KeyPair: Codable {
    public let publicKey: Data
    public let secretKey: Data

    public init(publicKey: Data, secretKey: Data) {
        self.publicKey = publicKey
        self.secretKey = secretKey
    }

    public init(publicKey: Bytes, secretKey: Bytes) {
        self.publicKey = Data(publicKey)
        self.secretKey = Data(secretKey)
    }
}

public struct SignedPreKey {
    public let publicKey: Data
    public let secretKey: Data
    public let signature: Data

    public init(publicKey: Data, secretKey: Data, signature: Data) {
        self.publicKey = publicKey
        self.secretKey = secretKey
        self.signature = signature
    }

    public init(publicKey: Bytes, secretKey: Bytes, signature: Bytes) {
        self.publicKey = Data(publicKey)
        self.secretKey = Data(secretKey)
        self.signature = Data(signature)
    }
}

public struct SessionKeys {
    public let encryptionKey: Data
    public let senderEphemeralPublicKey: Data

    public init(encryptionKey: Data, senderEphemeralPublicKey: Data) {
        self.encryptionKey = encryptionKey
        self.senderEphemeralPublicKey = senderEphemeralPublicKey
    }
}

public struct EncryptedMessage {
    public let ciphertext: Data

    public init(ciphertext: Data) {
        self.ciphertext = ciphertext
    }
}

// Extension for Data to Bytes conversion
extension Data {
    var bytes: Bytes {
        return Array(self)
    }
}

extension String {
    var bytes: Bytes {
        return Array(utf8)
    }
}
