import SwiftUI

struct ServerRowView: View {
    let server: ServerConnection
    let state: ConnectionManager.ConnectionState

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator

            VStack(alignment: .leading, spacing: 4) {
                Text(server.nickname)
                    .font(.headline)

                Text("\(server.username)@\(server.host)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                statusText
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    @ViewBuilder
    private var statusText: some View {
        switch state {
        case .connected:
            Text("Connected")
        case .connecting:
            Text("Connecting...")
        case .authenticating:
            Text("Authenticating...")
        case .failed(let reason):
            Text(reason)
        case .disconnected:
            if let lastConnected = server.lastConnected {
                Text("Last: \(lastConnected, format: .relative(presentation: .named))")
            } else {
                Text("Never connected")
            }
        }
    }

    private var statusColor: Color {
        switch state {
        case .connected: .green
        case .connecting, .authenticating: .orange
        case .failed: .red
        case .disconnected: .secondary
        }
    }
}
