import SwiftUI
import SwiftData

struct ServerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ServerConnection.nickname) private var servers: [ServerConnection]
    @State private var showingAddServer = false
    var connectionManager: ConnectionManager

    var body: some View {
        ScrollView {
            if servers.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: MMSpacing.md) {
                    ForEach(servers) { server in
                        NavigationLink(value: server) {
                            ServerCardView(
                                server: server,
                                state: connectionManager.state(for: server)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteServer(server)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, MMSpacing.sm)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("MobileMux")
        .navigationDestination(for: ServerConnection.self) { server in
            SessionListView(server: server, connectionManager: connectionManager)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddServer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddServer) {
            AddServerView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: MMSpacing.xl) {
            Spacer()
                .frame(height: 80)

            Image(systemName: "server.rack")
                .font(.system(size: 56))
                .foregroundStyle(MMColors.teal.opacity(0.6))

            VStack(spacing: MMSpacing.sm) {
                Text("No Servers")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add a server to connect to your\ntmux sessions remotely")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddServer = true
            } label: {
                Label("Add Server", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, MMSpacing.xl)
                    .padding(.vertical, MMSpacing.md)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteServer(_ server: ServerConnection) {
        connectionManager.disconnect(from: server)
        KeychainService.shared.deleteCredential(for: server)
        modelContext.delete(server)
    }
}

// MARK: - Server Card

struct ServerCardView: View {
    let server: ServerConnection
    let state: ConnectionManager.ConnectionState

    var body: some View {
        HStack(spacing: MMSpacing.lg) {
            // Server icon with status ring
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: "server.rack")
                    .font(.system(size: 18))
                    .foregroundStyle(iconForeground)
            }
            .overlay(alignment: .bottomTrailing) {
                statusDot
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: MMSpacing.xs) {
                Text(server.nickname)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(server.username)@\(server.host)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                statusLabel
                    .font(.caption2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .mmCard()
    }

    @ViewBuilder
    private var statusDot: some View {
        switch state {
        case .connected:
            PulseIndicator(color: MMColors.online)
        case .connecting, .authenticating:
            PulseIndicator(color: MMColors.warning)
        case .failed:
            Circle()
                .fill(MMColors.error)
                .frame(width: 8, height: 8)
        case .disconnected:
            Circle()
                .fill(MMColors.idle)
                .frame(width: 8, height: 8)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch state {
        case .connected:
            Text("Connected")
                .foregroundStyle(MMColors.online)
        case .connecting:
            Text("Connecting...")
                .foregroundStyle(MMColors.warning)
        case .authenticating:
            Text("Authenticating...")
                .foregroundStyle(MMColors.warning)
        case .failed(let reason):
            Text(reason)
                .foregroundStyle(MMColors.error)
                .lineLimit(1)
        case .disconnected:
            if let lastConnected = server.lastConnected {
                Text("Last connected \(lastConnected, format: .relative(presentation: .named))")
                    .foregroundStyle(.tertiary)
            } else {
                Text("Never connected")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var iconBackground: Color {
        switch state {
        case .connected: MMColors.online.opacity(0.15)
        case .connecting, .authenticating: MMColors.warning.opacity(0.15)
        case .failed: MMColors.error.opacity(0.15)
        case .disconnected: MMColors.idle.opacity(0.1)
        }
    }

    private var iconForeground: Color {
        switch state {
        case .connected: MMColors.online
        case .connecting, .authenticating: MMColors.warning
        case .failed: MMColors.error
        case .disconnected: MMColors.idle
        }
    }
}

#Preview {
    NavigationStack {
        ServerListView(connectionManager: ConnectionManager())
    }
    .modelContainer(for: ServerConnection.self, inMemory: true)
    .preferredColorScheme(.dark)
    .tint(MMColors.teal)
}
