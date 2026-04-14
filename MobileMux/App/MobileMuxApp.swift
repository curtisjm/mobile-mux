import SwiftUI
import SwiftData

@main
struct MobileMuxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ServerConnection.self)
    }
}
