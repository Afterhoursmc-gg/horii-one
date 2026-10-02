import Foundation

struct HoriiDeviceRegistration: Codable {
    let name: String
    let deviceIdentifier: String
    let deviceType: String
    let capabilities: [String: Bool]

    enum CodingKeys: String, CodingKey {
        case name
        case deviceIdentifier = "device_identifier"
        case deviceType = "device_type"
        case capabilities
    }
}

struct HoriiDeviceCredential: Codable {
    let deviceID: String
    let token: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case token
        case expiresAt = "expires_at"
    }
}

struct HoriiDevice: Codable, Identifiable {
    let id: String
    let name: String
    let deviceIdentifier: String
    let deviceType: String
    let capabilities: [String: Bool]
    let presence: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case deviceIdentifier = "device_identifier"
        case deviceType = "device_type"
        case capabilities, presence
    }
}

struct HoriiConversation: Codable, Identifiable {
    let id: String
    let title: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HoriiMessage: Codable, Identifiable {
    let id: String
    let conversationID: String
    let role: String
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationID = "conversation_id"
        case role, content
        case createdAt = "created_at"
    }
}
