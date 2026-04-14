import SwiftUI
import SwiftData

struct ServerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ServerConnection.nickname) private var servers: [ServerConnection]
    @State private var showingAddServer = false
    @State private var connectionManager = ConnectionManager()

    var body: some View {
        List {
            if servers.isEmpty {
                ContentUnavailableView(
                    "No Servers",
                    systemImage: "server.rack",
                    description: Text("Add a server to get started")
                )
            }

            ForEach(servers) { server in
                NavigationLink(value: server) {
                    ServerRowView(
                        server: server,
                        state: connectionManager.state(for: server)
                    )
                }
            }
            .onDelete(perform: deleteServers)
        }
        .navigationTitle("MobileMux")
        .navigationDestination(for: ServerConnection.self) { server in
            SessionListView(server: server, connectionManager: connectionManager)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddServer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddServer) {
            AddServerView()
        }
    }

    private func deleteServers(at offsets: IndexSet) {
        for index in offsets {
            let server = servers[index]
            connectionManager.disconnect(from: server)
            KeychainService.shared.deleteCredential(for: server)
            modelContext.delete(server)
        }
    }
}
