import Foundation

public struct Conversation: Codable, Identifiable, Equatable {
    public let id: UUID
    public let parentId: UUID
    public let providerId: UUID
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case providerId = "provider_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        parentId: UUID,
        providerId: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.parentId = parentId
        self.providerId = providerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func otherUserId(currentUserId: UUID) -> UUID {
        return currentUserId == parentId ? providerId : parentId
    }
}

public struct ConversationMetadata: Codable, Identifiable {
    public let id: UUID
    public let lastMessageId: UUID?
    public let lastMessageAt: Date?
    public let parentUnreadCount: Int
    public let providerUnreadCount: Int
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "conversation_id"
        case lastMessageId = "last_message_id"
        case lastMessageAt = "last_message_at"
        case parentUnreadCount = "parent_unread_count"
        case providerUnreadCount = "provider_unread_count"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID,
        lastMessageId: UUID? = nil,
        lastMessageAt: Date? = nil,
        parentUnreadCount: Int = 0,
        providerUnreadCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.lastMessageId = lastMessageId
        self.lastMessageAt = lastMessageAt
        self.parentUnreadCount = parentUnreadCount
        self.providerUnreadCount = providerUnreadCount
        self.updatedAt = updatedAt
    }

    public func unreadCount(for userType: UserType) -> Int {
        switch userType {
        case .parent:
            return parentUnreadCount
        case .provider:
            return providerUnreadCount
        }
    }
}

// Combined view for UI
public struct ConversationWithMetadata: Identifiable, Equatable {
    public let id: UUID
    public let conversation: Conversation
    public let metadata: ConversationMetadata?
    public let otherUser: Profile

    public init(conversation: Conversation, metadata: ConversationMetadata?, otherUser: Profile) {
        self.id = conversation.id
        self.conversation = conversation
        self.metadata = metadata
        self.otherUser = otherUser
    }
}
