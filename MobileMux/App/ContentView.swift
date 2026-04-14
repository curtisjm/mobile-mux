import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ServerListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ServerConnection.self, inMemory: true)
}
