import Foundation
import SwiftUI

/// Manages the lifecycle of SSH connections and tmux control mode clients
@MainActor
@Observable
final class ConnectionManager {
    private(set) var activeConnections: [UUID: ActiveConnection] = [:]
    var isDemoMode = false

    struct ActiveConnection {
        let server: ServerConnection
        let ssh: SSHClientProtocol
        let tmux: TmuxControlModeClient
        var state: ConnectionState
    }

    enum ConnectionState: Equatable {
        case connecting
        case authenticating
        case connected
        case failed(String)
        case disconnected
    }

    func connect(to server: ServerConnection) async throws -> ActiveConnection {
        let ssh = SSHClientImpl()
        let tmux = TmuxControlModeClient()

        var connection = ActiveConnection(
            server: server,
            ssh: ssh,
            tmux: tmux,
            state: .connecting
        )
        activeConnections[server.id] = connection

        do {
            try await ssh.connect(host: server.host, port: server.port)
            connection.state = .authenticating
            activeConnections[server.id] = connection

            let credential = try KeychainService.shared.loadCredential(for: server)
            try await ssh.authenticate(username: server.username, credential: credential)

            connection.state = .connected
            activeConnections[server.id] = connection
            server.lastConnected = Date()

            return connection
        } catch {
            connection.state = .failed(error.localizedDescription)
            activeConnections[server.id] = connection
            throw error
        }
    }

    func disconnect(from server: ServerConnection) {
        guard let connection = activeConnections[server.id] else { return }
        connection.ssh.disconnect()
        activeConnections[server.id]?.state = .disconnected
        activeConnections.removeValue(forKey: server.id)
    }

    func state(for server: ServerConnection) -> ConnectionState {
        if isDemoServer(server) {
            return .connected
        }
        return activeConnections[server.id]?.state ?? .disconnected
    }

    func isDemoServer(_ server: ServerConnection) -> Bool {
        isDemoMode && PreviewData.demoServers.contains { $0.id == server.id }
    }
}
