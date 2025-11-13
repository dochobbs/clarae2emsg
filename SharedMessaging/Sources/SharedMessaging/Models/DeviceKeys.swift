import Foundation

public struct DeviceKeys: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let deviceId: String
    public let identityKey: String
    public let signedPrekey: String
    public let signedPrekeySignature: String
    public let oneTimePrekeysjson: String
    public let apnsToken: String?
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case deviceId = "device_id"
        case identityKey = "identity_key"
        case signedPrekey = "signed_prekey"
        case signedPrekeySignature = "signed_prekey_signature"
        case oneTimePrekeys = "one_time_prekeys"
        case apnsToken = "apns_token"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        deviceId: String,
        identityKey: String,
        signedPrekey: String,
        signedPrekeySignature: String,
        oneTimePrekeys: String = "[]",
        apnsToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.deviceId = deviceId
        self.identityKey = identityKey
        self.signedPrekey = signedPrekey
        self.signedPrekeySignature = signedPrekeySignature
        self.oneTimePrekeysjson = oneTimePrekeys
        self.apnsToken = apnsToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
