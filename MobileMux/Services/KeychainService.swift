import Foundation
import Security

/// Stores and retrieves SSH credentials from the iOS Keychain
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let servicePrefix = "com.curtisjm.MobileMux"

    /// Save a password for a server connection
    func savePassword(_ password: String, for server: ServerConnection) throws {
        let tag = "\(servicePrefix).password.\(server.id.uuidString)"
        let data = password.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecValueData as String: data,
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        server.credentialTag = tag
    }

    /// Save an SSH private key for a server connection
    func savePrivateKey(_ keyData: Data, for server: ServerConnection) throws {
        let tag = "\(servicePrefix).key.\(server.id.uuidString)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecValueData as String: keyData,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        server.credentialTag = tag
    }

    /// Load the credential for a server connection
    func loadCredential(for server: ServerConnection) throws -> SSHCredential {
        guard let tag = server.credentialTag else {
            throw KeychainError.notFound
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.notFound
        }

        if server.authMethod == .password {
            guard let password = String(data: data, encoding: .utf8) else {
                throw KeychainError.corruptData
            }
            return .password(password)
        } else {
            return .privateKey(data: data, passphrase: nil)
        }
    }

    /// Delete stored credential for a server connection
    func deleteCredential(for server: ServerConnection) {
        guard let tag = server.credentialTag else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
        ]
        SecItemDelete(query as CFDictionary)
        server.credentialTag = nil
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case notFound
    case corruptData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): "Keychain save failed: \(status)"
        case .notFound: "Credential not found in Keychain"
        case .corruptData: "Stored credential data is corrupt"
        }
    }
}
