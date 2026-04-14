import SwiftUI

/// Reusable status badge for agent and connection states
struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String?

    init(_ text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // Convenience initializers for common states
    static var connected: StatusBadge {
        StatusBadge("Connected", color: .green, icon: "circle.fill")
    }

    static var disconnected: StatusBadge {
        StatusBadge("Disconnected", color: .secondary, icon: "circle")
    }

    static var thinking: StatusBadge {
        StatusBadge("Thinking", color: .orange, icon: "brain")
    }

    static var writing: StatusBadge {
        StatusBadge("Writing", color: .blue, icon: "pencil")
    }

    static var waiting: StatusBadge {
        StatusBadge("Waiting", color: .yellow, icon: "pause.circle")
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge.connected
        StatusBadge.disconnected
        StatusBadge.thinking
        StatusBadge.writing
        StatusBadge.waiting
        StatusBadge("Custom", color: .purple, icon: "star.fill")
    }
    .padding()
}
