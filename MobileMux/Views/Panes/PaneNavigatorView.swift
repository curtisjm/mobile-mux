import SwiftUI

struct PaneNavigatorView: View {
    let session: TmuxSession
    let connectionManager: ConnectionManager
    let server: ServerConnection

    @State private var selectedWindowIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Pane cards for the selected window
            ScrollView {
                if selectedWindowIndex < session.windows.count {
                    let window = session.windows[selectedWindowIndex]
                    LazyVStack(spacing: 12) {
                        ForEach(window.panes) { pane in
                            PaneCardView(pane: pane)
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Window tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(session.windows.enumerated()), id: \.element.id) { index, window in
                        Button {
                            withAnimation(.snappy) {
                                selectedWindowIndex = index
                            }
                        } label: {
                            Text(window.name.isEmpty ? "\(index)" : window.name)
                                .font(.caption)
                                .fontWeight(index == selectedWindowIndex ? .semibold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    index == selectedWindowIndex
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(.bar)
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50, selectedWindowIndex < session.windows.count - 1 {
                        withAnimation(.snappy) { selectedWindowIndex += 1 }
                    } else if value.translation.width > 50, selectedWindowIndex > 0 {
                        withAnimation(.snappy) { selectedWindowIndex -= 1 }
                    }
                }
        )
    }
}

struct PaneCardView: View {
    let pane: TmuxPane

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label(
                    pane.agentType == .claudeCode ? "Claude Code" : "Terminal",
                    systemImage: pane.agentType == .claudeCode ? "cpu" : "terminal"
                )
                .font(.subheadline)
                .fontWeight(.medium)

                Spacer()

                if let command = pane.currentCommand {
                    Text(command)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Output preview
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(pane.recentOutput.suffix(6).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.fill.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Interaction hint
            HStack {
                Spacer()
                Label("Tap to interact", systemImage: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
