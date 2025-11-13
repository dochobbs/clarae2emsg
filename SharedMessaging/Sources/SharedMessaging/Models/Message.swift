import Foundation

public enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
}

public struct Message: Codable, Identifiable, Equatable {
    public let id: UUID
    public let conversationId: UUID
    public let senderId: UUID
    public let recipientId: UUID
    public let encryptedContent: String
    public let senderDeviceId: String
    public let recipientDeviceId: String
    public let status: MessageStatus
    public let sentAt: Date
    public let deliveredAt: Date?
    public let readAt: Date?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case recipientId = "recipient_id"
        case encryptedContent = "encrypted_content"
        case senderDeviceId = "sender_device_id"
        case recipientDeviceId = "recipient_device_id"
        case status
        case sentAt = "sent_at"
        case deliveredAt = "delivered_at"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        conversationId: UUID,
        senderId: UUID,
        recipientId: UUID,
        encryptedContent: String,
        senderDeviceId: String,
        recipientDeviceId: String,
        status: MessageStatus = .sent,
        sentAt: Date = Date(),
        deliveredAt: Date? = nil,
        readAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.recipientId = recipientId
        self.encryptedContent = encryptedContent
        self.senderDeviceId = senderDeviceId
        self.recipientDeviceId = recipientDeviceId
        self.status = status
        self.sentAt = sentAt
        self.deliveredAt = deliveredAt
        self.readAt = readAt
        self.createdAt = createdAt
    }
}

// Decrypted message for UI display
public struct DecryptedMessage: Identifiable, Equatable {
    public let id: UUID
    public let conversationId: UUID
    public let senderId: UUID
    public let recipientId: UUID
    public let content: String // Decrypted content
    public let status: MessageStatus
    public let sentAt: Date
    public let deliveredAt: Date?
    public let readAt: Date?

    public init(from message: Message, decryptedContent: String) {
        self.id = message.id
        self.conversationId = message.conversationId
        self.senderId = message.senderId
        self.recipientId = message.recipientId
        self.content = decryptedContent
        self.status = message.status
        self.sentAt = message.sentAt
        self.deliveredAt = message.deliveredAt
        self.readAt = message.readAt
    }

    public init(
        id: UUID,
        conversationId: UUID,
        senderId: UUID,
        recipientId: UUID,
        content: String,
        status: MessageStatus = .sent,
        sentAt: Date = Date(),
        deliveredAt: Date? = nil,
        readAt: Date? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.status = status
        self.sentAt = sentAt
        self.deliveredAt = deliveredAt
        self.readAt = readAt
    }
}
