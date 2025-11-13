import Foundation

public enum UserType: String, Codable {
    case parent
    case provider
}

public struct Profile: Codable, Identifiable, Equatable {
    public let id: UUID
    public let userType: UserType
    public let fullName: String
    public let email: String
    public let appleUserId: String?
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userType = "user_type"
        case fullName = "full_name"
        case email
        case appleUserId = "apple_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID,
        userType: UserType,
        fullName: String,
        email: String,
        appleUserId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userType = userType
        self.fullName = fullName
        self.email = email
        self.appleUserId = appleUserId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
