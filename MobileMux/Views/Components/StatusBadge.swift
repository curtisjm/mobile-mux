import SwiftUI

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
                    .font(.system(size: 9))
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, MMSpacing.sm)
        .padding(.vertical, MMSpacing.xs)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // Common states
    static var connected: StatusBadge {
        StatusBadge("Connected", color: MMColors.online, icon: "circle.fill")
    }

    static var disconnected: StatusBadge {
        StatusBadge("Disconnected", color: MMColors.idle, icon: "circle")
    }

    static var thinking: StatusBadge {
        StatusBadge("Thinking", color: MMColors.warning, icon: "brain")
    }

    static var writing: StatusBadge {
        StatusBadge("Writing", color: MMColors.indigo, icon: "pencil")
    }

    static var waiting: StatusBadge {
        StatusBadge("Waiting for input", color: MMColors.warning, icon: "hand.raised")
    }

    static var running: StatusBadge {
        StatusBadge("Running", color: MMColors.teal, icon: "play.fill")
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge.connected
        StatusBadge.disconnected
        StatusBadge.thinking
        StatusBadge.writing
        StatusBadge.waiting
        StatusBadge.running
    }
    .padding()
    .preferredColorScheme(.dark)
}
