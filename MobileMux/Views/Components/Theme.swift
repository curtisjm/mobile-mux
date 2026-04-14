import SwiftUI

// MARK: - Design Tokens

enum MMColors {
    // Brand
    static let accent = Color("AccentColor")
    static let teal = Color(red: 0.33, green: 0.84, blue: 0.78)
    static let indigo = Color(red: 0.42, green: 0.45, blue: 0.95)

    // Status
    static let online = Color(red: 0.30, green: 0.85, blue: 0.47)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let error = Color(red: 0.95, green: 0.35, blue: 0.38)
    static let idle = Color(red: 0.55, green: 0.55, blue: 0.58)

    // Terminal
    static let terminalBg = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let terminalText = Color(red: 0.85, green: 0.87, blue: 0.90)
    static let terminalDim = Color(red: 0.45, green: 0.47, blue: 0.50)

    // Surface layers (adaptive to light/dark mode)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let cardBorder = Color(.separator).opacity(0.5)
    static let surfaceRaised = Color(.tertiarySystemGroupedBackground)
}

enum MMSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum MMRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - Card Style

struct MMCard: ViewModifier {
    var padding: CGFloat = MMSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MMColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MMRadius.md)
                    .strokeBorder(MMColors.cardBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func mmCard(padding: CGFloat = MMSpacing.lg) -> some View {
        modifier(MMCard(padding: padding))
    }
}

// MARK: - Terminal Output Block

struct TerminalBlock: View {
    let lines: [String]
    var maxLines: Int = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.suffix(maxLines).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(MMColors.terminalText)
                    .lineLimit(1)
            }

            if lines.isEmpty {
                Text("No output")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(MMColors.terminalDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MMSpacing.md)
        .background(MMColors.terminalBg)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
    }
}

// MARK: - Pulse Indicator

struct PulseIndicator: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing ? 2.2 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Preview Helpers

#Preview("Theme Components") {
    ScrollView {
        VStack(spacing: MMSpacing.lg) {
            // Cards
            VStack(alignment: .leading, spacing: MMSpacing.sm) {
                Text("Example Card")
                    .font(.headline)
                Text("With card styling applied")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mmCard()

            // Terminal block
            TerminalBlock(lines: [
                "$ gt mol status",
                "Hook: mayor/",
                "No molecule attached",
                "Ready: 10 issues",
            ])

            // Pulse indicators
            HStack(spacing: MMSpacing.lg) {
                HStack(spacing: MMSpacing.sm) {
                    PulseIndicator(color: MMColors.online)
                    Text("Connected")
                        .font(.caption)
                }
                HStack(spacing: MMSpacing.sm) {
                    PulseIndicator(color: MMColors.warning)
                    Text("Connecting")
                        .font(.caption)
                }
                HStack(spacing: MMSpacing.sm) {
                    PulseIndicator(color: MMColors.error)
                    Text("Error")
                        .font(.caption)
                }
            }

            // Status badges
            HStack(spacing: MMSpacing.sm) {
                StatusBadge.connected
                StatusBadge.thinking
                StatusBadge.writing
                StatusBadge.waiting
            }
        }
        .padding()
    }
}
