import SwiftUI

struct SessionListView: View {
    let server: ServerConnection
    let connectionManager: ConnectionManager

    @State private var sessions: [TmuxSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingNewSession = false
    @State private var newSessionName = ""

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if sessions.isEmpty {
                emptyView
            } else {
                sessionList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(server.nickname)
        .navigationDestination(for: String.self) { sessionId in
            if let session = sessions.first(where: { $0.id == sessionId }) {
                PaneNavigatorView(
                    session: session,
                    connectionManager: connectionManager,
                    server: server
                )
            }
        }
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewSession = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await loadSessions() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("New Session", isPresented: $showingNewSession) {
            TextField("Session name", text: $newSessionName)
            Button("Create") {
                Task { await createSession() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for the new tmux session")
        }
        .task {
            await loadSessions()
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: MMSpacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Connecting to \(server.host)...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: MMSpacing.xl) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(MMColors.error.opacity(0.7))

            VStack(spacing: MMSpacing.sm) {
                Text("Connection Failed")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MMSpacing.xxl)
            }

            Button {
                Task { await loadSessions() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, MMSpacing.xl)
                    .padding(.vertical, MMSpacing.md)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: MMSpacing.xl) {
            Spacer()

            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundStyle(MMColors.teal.opacity(0.6))

            VStack(spacing: MMSpacing.sm) {
                Text("No Sessions")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("No active tmux sessions on this server")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingNewSession = true
            } label: {
                Label("New Session", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, MMSpacing.xl)
                    .padding(.vertical, MMSpacing.md)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: MMSpacing.md) {
                ForEach(sessions) { session in
                    NavigationLink(value: session.id) {
                        SessionCardView(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, MMSpacing.sm)
        }
    }

    // MARK: - Actions

    private func loadSessions() async {
        isLoading = true
        errorMessage = nil
        do {
            let connection = try await connectionManager.connect(to: server)
            sessions = try await connection.tmux.listSessions(via: connection.ssh)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func createSession() async {
        guard !newSessionName.isEmpty else { return }
        guard let connection = connectionManager.activeConnections[server.id] else { return }
        do {
            try await connection.tmux.newSession(name: newSessionName, via: connection.ssh)
            newSessionName = ""
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("With Sessions") {
    NavigationStack {
        SessionListView(
            server: {
                let s = ServerConnection(nickname: "dev-server", host: "dev.example.com", username: "curtis")
                return s
            }(),
            connectionManager: ConnectionManager()
        )
    }
    .preferredColorScheme(.dark)
    .tint(MMColors.teal)
}
