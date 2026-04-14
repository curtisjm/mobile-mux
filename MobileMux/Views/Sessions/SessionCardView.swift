import SwiftUI

struct SessionCardView: View {
    let session: TmuxSession

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MMSpacing.xs) {
                    Text(session.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(session.created, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if session.isAttached {
                    StatusBadge("Attached", color: MMColors.online, icon: "link")
                } else {
                    StatusBadge("Detached", color: MMColors.idle)
                }
            }

            // Stats row
            HStack(spacing: MMSpacing.lg) {
                Label("\(session.windowCount)", systemImage: "rectangle.split.3x1")
                Label("\(session.paneCount)", systemImage: "square.split.2x2")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Window name pills
            if !session.windows.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(session.windows) { window in
                        HStack(spacing: 4) {
                            if window.panes.contains(where: { $0.agentType == .claudeCode }) {
                                Image(systemName: "cpu")
                                    .font(.system(size: 8))
                            }
                            Text(window.name.isEmpty ? "window \(window.index)" : window.name)
                        }
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, MMSpacing.sm)
                        .padding(.vertical, MMSpacing.xs)
                        .foregroundStyle(
                            window.isActive ? MMColors.teal : .secondary
                        )
                        .background(
                            window.isActive
                                ? MMColors.teal.opacity(0.12)
                                : Color(.tertiarySystemFill)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .mmCard()
    }
}

/// Simple horizontal flow layout for window name pills
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: MMSpacing.md) {
            SessionCardView(session: PreviewData.sessions[0])
            SessionCardView(session: PreviewData.sessions[1])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
