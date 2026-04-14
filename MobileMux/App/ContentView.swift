import SwiftUI

struct ContentView: View {
    @State private var connectionManager = ConnectionManager()

    var body: some View {
        NavigationStack {
            ServerListView(connectionManager: connectionManager)
        }
        .tint(MMColors.teal)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ServerConnection.self, inMemory: true)
}
