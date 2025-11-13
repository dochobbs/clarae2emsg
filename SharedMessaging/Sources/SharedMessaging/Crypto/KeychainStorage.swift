import Foundation
import Security

/// Secure keychain storage for encryption keys
public class KeychainStorage {
    private let service: String

    public init(service: String) {
        self.service = service
    }

    // MARK: - Save

    public func save(_ data: Data, forKey key: String) throws {
        // Delete existing item if present
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Load

    public func load(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    // MARK: - Delete

    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Convenience Methods for KeyPair

    public func saveKeyPair(_ keyPair: KeyPair, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(keyPair)
        try save(data, forKey: key)
    }

    public func loadKeyPair(forKey key: String) throws -> KeyPair {
        let data = try load(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(KeyPair.self, from: data)
    }

    // MARK: - Convenience Methods for Session Keys

    public func saveSessionKey(_ sessionKey: Data, forConversation conversationId: String) throws {
        try save(sessionKey, forKey: "session_\(conversationId)")
    }

    public func loadSessionKey(forConversation conversationId: String) throws -> Data {
        return try load(forKey: "session_\(conversationId)")
    }

    public func deleteSessionKey(forConversation conversationId: String) throws {
        try delete(forKey: "session_\(conversationId)")
    }
}

// MARK: - Errors

public enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case unexpectedData
    case itemNotFound

    public var localizedDescription: String {
        switch self {
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .unexpectedData:
            return "Unexpected keychain data"
        case .itemNotFound:
            return "Keychain item not found"
        }
    }
}
