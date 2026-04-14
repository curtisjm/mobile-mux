import SwiftUI

struct PaneNavigatorView: View {
    let session: TmuxSession
    let connectionManager: ConnectionManager
    let server: ServerConnection

    @State private var selectedWindowIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Window tab bar at top
            windowTabBar
                .background(.bar)

            Divider()

            // Pane cards
            ScrollView {
                if selectedWindowIndex < session.windows.count {
                    let window = session.windows[selectedWindowIndex]
                    LazyVStack(spacing: MMSpacing.md) {
                        ForEach(window.panes) { pane in
                            PaneCardView(pane: pane)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, MMSpacing.md)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50, selectedWindowIndex < session.windows.count - 1 {
                        withAnimation(.snappy(duration: 0.25)) { selectedWindowIndex += 1 }
                    } else if value.translation.width > 50, selectedWindowIndex > 0 {
                        withAnimation(.snappy(duration: 0.25)) { selectedWindowIndex -= 1 }
                    }
                }
        )
    }

    private var windowTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MMSpacing.xs) {
                    ForEach(Array(session.windows.enumerated()), id: \.element.id) { index, window in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                selectedWindowIndex = index
                            }
                        } label: {
                            HStack(spacing: MMSpacing.xs) {
                                if window.panes.contains(where: { $0.agentType == .claudeCode }) {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 10))
                                }
                                Text(window.name.isEmpty ? "\(index)" : window.name)
                                    .font(.subheadline)
                                    .fontWeight(index == selectedWindowIndex ? .semibold : .regular)
                            }
                            .padding(.horizontal, MMSpacing.md)
                            .padding(.vertical, MMSpacing.sm)
                            .foregroundStyle(
                                index == selectedWindowIndex
                                    ? MMColors.teal
                                    : .secondary
                            )
                            .background(
                                index == selectedWindowIndex
                                    ? MMColors.teal.opacity(0.12)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, MMSpacing.sm)
            }
            .onChange(of: selectedWindowIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Pane Card

struct PaneCardView: View {
    let pane: TmuxPane

    private var isAgent: Bool { pane.agentType == .claudeCode }

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpacing.md) {
            // Header
            HStack {
                HStack(spacing: MMSpacing.sm) {
                    Image(systemName: isAgent ? "cpu" : "terminal")
                        .font(.subheadline)
                        .foregroundStyle(isAgent ? MMColors.indigo : MMColors.teal)

                    Text(isAgent ? "Claude Code" : "Terminal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                if let command = pane.currentCommand {
                    Text(command)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            // Output preview
            TerminalBlock(lines: pane.recentOutput)

            // Footer
            HStack {
                if isAgent {
                    StatusBadge.writing
                }

                Spacer()

                Label("Tap to interact", systemImage: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .mmCard()
        .overlay(
            RoundedRectangle(cornerRadius: MMRadius.md)
                .strokeBorder(
                    isAgent
                        ? MMColors.indigo.opacity(0.3)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Previews

#Preview("Pane Navigator") {
    NavigationStack {
        PaneNavigatorView(
            session: PreviewData.sessions[0],
            connectionManager: ConnectionManager(),
            server: ServerConnection(nickname: "dev", host: "dev.example.com", username: "curtis")
        )
    }
    .preferredColorScheme(.dark)
    .tint(MMColors.teal)
}

#Preview("Pane Cards") {
    ScrollView {
        VStack(spacing: MMSpacing.md) {
            PaneCardView(pane: PreviewData.sessions[0].windows[0].panes[0])
            PaneCardView(pane: PreviewData.sessions[0].windows[3].panes[0])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
