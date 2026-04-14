import Foundation
import SwiftData

enum AuthMethod: String, Codable, CaseIterable {
    case password
    case key
}

@Model
final class ServerConnection {
    var id: UUID
    var nickname: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    /// Keychain item identifier for the stored credential (password or private key)
    var credentialTag: String?
    var lastConnected: Date?
    var createdAt: Date

    init(
        nickname: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .key
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.createdAt = Date()
    }
}
