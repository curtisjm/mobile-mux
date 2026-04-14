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
                ProgressView("Connecting...")
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Connection Failed",
                    systemImage: "xmark.circle",
                    description: Text(error)
                )
            } else if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "terminal",
                    description: Text("No active tmux sessions on this server")
                ) {
                    Button("New Session") {
                        showingNewSession = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(sessions) { session in
                    NavigationLink(value: session.id) {
                        SessionCardView(session: session)
                    }
                }
            }
        }
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
                        Image(systemName: "plus")
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
        }
        .task {
            await loadSessions()
        }
    }

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
