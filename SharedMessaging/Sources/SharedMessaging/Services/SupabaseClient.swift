import Foundation
import Supabase
import AuthenticationServices

public class SupabaseClient {
    public static let shared = SupabaseClient()

    private var client: Supabase.Client?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        setupDateFormatters()
    }

    private func setupDateFormatters() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }

    // MARK: - Configuration

    public func configure(supabaseURL: String, supabaseKey: String) {
        client = Supabase.Client(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }

    private func ensureClient() throws -> Supabase.Client {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        return client
    }

    // MARK: - Authentication

    public func signInWithApple(idToken: String, nonce: String) async throws -> Profile {
        let client = try ensureClient()

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )

        guard let userId = UUID(uuidString: session.user.id.uuidString) else {
            throw SupabaseError.invalidUserId
        }

        // Try to get existing profile
        do {
            let profile: Profile = try await client.database
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return profile
        } catch {
            // Profile doesn't exist, needs to be created by user
            throw SupabaseError.profileNotFound
        }
    }

    public func createProfile(
        fullName: String,
        email: String,
        userType: UserType,
        appleUserId: String?
    ) async throws -> Profile {
        let client = try ensureClient()

        guard let userId = try await currentUserId() else {
            throw SupabaseError.notAuthenticated
        }

        let profile = Profile(
            id: userId,
            userType: userType,
            fullName: fullName,
            email: email,
            appleUserId: appleUserId
        )

        let _: Profile = try await client.database
            .from("profiles")
            .insert(profile)
            .select()
            .single()
            .execute()
            .value

        return profile
    }

    public func signOut() async throws {
        let client = try ensureClient()
        try await client.auth.signOut()
    }

    public func currentUserId() async throws -> UUID? {
        let client = try ensureClient()

        guard let session = try await client.auth.session else {
            return nil
        }

        return UUID(uuidString: session.user.id.uuidString)
    }

    public func currentUser() async throws -> Profile? {
        guard let userId = try await currentUserId() else {
            return nil
        }

        let client = try ensureClient()

        let profile: Profile = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }

    // MARK: - Profiles

    public func fetchProfile(userId: UUID) async throws -> Profile {
        let client = try ensureClient()

        let profile: Profile = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }

    public func fetchAllProfiles(userType: UserType? = nil) async throws -> [Profile] {
        let client = try ensureClient()

        var query = client.database
            .from("profiles")
            .select()

        if let userType = userType {
            query = query.eq("user_type", value: userType.rawValue)
        }

        let profiles: [Profile] = try await query.execute().value
        return profiles
    }

    // MARK: - Device Keys

    public func saveDeviceKeys(_ keys: DeviceKeys) async throws {
        let client = try ensureClient()

        let _: DeviceKeys = try await client.database
            .from("device_keys")
            .upsert(keys)
            .select()
            .single()
            .execute()
            .value
    }

    public func fetchDeviceKeys(userId: UUID, deviceId: String) async throws -> DeviceKeys? {
        let client = try ensureClient()

        let keys: DeviceKeys = try await client.database
            .from("device_keys")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("device_id", value: deviceId)
            .single()
            .execute()
            .value

        return keys
    }

    public func fetchUserDeviceKeys(userId: UUID) async throws -> [DeviceKeys] {
        let client = try ensureClient()

        let keys: [DeviceKeys] = try await client.database
            .from("device_keys")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return keys
    }

    // MARK: - Conversations

    public func createConversation(parentId: UUID, providerId: UUID) async throws -> Conversation {
        let client = try ensureClient()

        let conversation = Conversation(
            parentId: parentId,
            providerId: providerId
        )

        let created: Conversation = try await client.database
            .from("conversations")
            .insert(conversation)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    public func fetchConversation(id: UUID) async throws -> Conversation {
        let client = try ensureClient()

        let conversation: Conversation = try await client.database
            .from("conversations")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return conversation
    }

    public func fetchConversations(for userId: UUID) async throws -> [Conversation] {
        let client = try ensureClient()

        let conversations: [Conversation] = try await client.database
            .from("conversations")
            .select()
            .or("parent_id.eq.\(userId.uuidString),provider_id.eq.\(userId.uuidString)")
            .execute()
            .value

        return conversations
    }

    public func fetchConversationMetadata(conversationId: UUID) async throws -> ConversationMetadata? {
        let client = try ensureClient()

        let metadata: ConversationMetadata = try await client.database
            .from("conversation_metadata")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .single()
            .execute()
            .value

        return metadata
    }

    // MARK: - Messages

    public func sendMessage(_ message: Message) async throws -> Message {
        let client = try ensureClient()

        let sent: Message = try await client.database
            .from("messages")
            .insert(message)
            .select()
            .single()
            .execute()
            .value

        return sent
    }

    public func fetchMessages(conversationId: UUID, limit: Int = 50) async throws -> [Message] {
        let client = try ensureClient()

        let messages: [Message] = try await client.database
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return messages.reversed()
    }

    public func updateMessageStatus(messageId: UUID, status: MessageStatus) async throws {
        let client = try ensureClient()

        var updates: [String: Any] = ["status": status.rawValue]

        switch status {
        case .delivered:
            updates["delivered_at"] = ISO8601DateFormatter().string(from: Date())
        case .read:
            updates["read_at"] = ISO8601DateFormatter().string(from: Date())
        default:
            break
        }

        let _: Message = try await client.database
            .from("messages")
            .update(updates)
            .eq("id", value: messageId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    public func resetUnreadCount(conversationId: UUID, userId: UUID) async throws {
        let client = try ensureClient()

        try await client.database
            .rpc("reset_unread_count", params: [
                "p_conversation_id": conversationId.uuidString,
                "p_user_id": userId.uuidString
            ])
            .execute()
    }

    // MARK: - Real-time Subscriptions

    public func subscribeToMessages(
        conversationId: UUID,
        onMessage: @escaping (Message) -> Void
    ) async throws -> RealtimeChannel {
        let client = try ensureClient()

        let channel = await client.realtime.channel("messages:\(conversationId.uuidString)")

        let changes = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "conversation_id=eq.\(conversationId.uuidString)"
        )

        await channel.subscribe()

        Task {
            for await change in changes {
                if let message = try? decoder.decode(Message.self, from: JSONEncoder().encode(change.record)) {
                    onMessage(message)
                }
            }
        }

        return channel
    }

    public func unsubscribe(channel: RealtimeChannel) async {
        await client?.realtime.remove(channel)
    }
}

// MARK: - Errors

public enum SupabaseError: Error, LocalizedError {
    case notConfigured
    case notAuthenticated
    case invalidUserId
    case profileNotFound

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase client not configured"
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidUserId:
            return "Invalid user ID"
        case .profileNotFound:
            return "Profile not found"
        }
    }
}
