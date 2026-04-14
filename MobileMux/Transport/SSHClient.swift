import Foundation

/// SSH connection errors
enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case channelOpenFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason): "Connection failed: \(reason)"
        case .authenticationFailed: "Authentication failed"
        case .channelOpenFailed: "Failed to open SSH channel"
        case .timeout: "Connection timed out"
        }
    }
}

/// Credentials for SSH authentication
enum SSHCredential {
    case password(String)
    case privateKey(data: Data, passphrase: String?)
}

/// Protocol for SSH transport — allows mocking in tests
protocol SSHClientProtocol: Sendable {
    func connect(host: String, port: Int) async throws
    func authenticate(username: String, credential: SSHCredential) async throws
    func execute(_ command: String) async throws -> String
    func openInteractiveChannel() async throws -> SSHChannel
    func disconnect()
}

/// Interactive SSH channel for long-running commands (tmux -CC)
protocol SSHChannel: Sendable {
    func write(_ data: Data) async throws
    var outputStream: AsyncStream<Data> { get }
    func close()
}

// MARK: - Placeholder implementation
// Real implementation will wrap NMSSH, libssh2, or a similar library.
// This stub defines the interface that the rest of the app codes against.

final class SSHClientImpl: SSHClientProtocol {
    func connect(host: String, port: Int) async throws {
        // TODO: Implement with SSH library
        throw SSHError.connectionFailed("Not yet implemented")
    }

    func authenticate(username: String, credential: SSHCredential) async throws {
        throw SSHError.authenticationFailed
    }

    func execute(_ command: String) async throws -> String {
        throw SSHError.channelOpenFailed
    }

    func openInteractiveChannel() async throws -> SSHChannel {
        throw SSHError.channelOpenFailed
    }

    func disconnect() {}
}
