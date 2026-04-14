import Foundation

// MARK: - tmux Control Mode Protocol
//
// tmux -CC outputs structured notifications:
//   %begin <time> <command-num> <flags>
//   %end <time> <command-num> <flags>
//   %error <time> <command-num> <flags>
//   %output <pane-id> <data>
//   %session-changed <session-id> <session-name>
//   %session-renamed <new-name>
//   %window-add <window-id>
//   %window-close <window-id>
//   %window-renamed <window-id> <new-name>
//   %layout-change <window-id> <layout-string>
//   %pane-mode-changed <pane-id>
//   %exit [reason]
//
// Commands are sent as plain text lines and produce %begin/%end blocks.

/// Events parsed from tmux control mode output
enum TmuxEvent {
    case sessionChanged(sessionId: String, name: String)
    case sessionRenamed(name: String)
    case windowAdd(windowId: String)
    case windowClose(windowId: String)
    case windowRenamed(windowId: String, name: String)
    case layoutChange(windowId: String, layout: String)
    case output(paneId: String, data: String)
    case paneModeChanged(paneId: String)
    case commandOutput(commandNum: Int, text: String)
    case exit(reason: String?)
    case unknown(line: String)
}

/// Parses raw lines from tmux -CC into structured events
struct TmuxControlModeParser {
    func parse(line: String) -> TmuxEvent {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown(line: line) }

        if trimmed.hasPrefix("%output ") {
            return parseOutput(trimmed)
        } else if trimmed.hasPrefix("%session-changed ") {
            return parseSessionChanged(trimmed)
        } else if trimmed.hasPrefix("%session-renamed ") {
            let name = String(trimmed.dropFirst("%session-renamed ".count))
            return .sessionRenamed(name: name)
        } else if trimmed.hasPrefix("%window-add ") {
            let windowId = String(trimmed.dropFirst("%window-add ".count))
            return .windowAdd(windowId: windowId)
        } else if trimmed.hasPrefix("%window-close ") {
            let windowId = String(trimmed.dropFirst("%window-close ".count))
            return .windowClose(windowId: windowId)
        } else if trimmed.hasPrefix("%window-renamed ") {
            return parseWindowRenamed(trimmed)
        } else if trimmed.hasPrefix("%layout-change ") {
            return parseLayoutChange(trimmed)
        } else if trimmed.hasPrefix("%pane-mode-changed ") {
            let paneId = String(trimmed.dropFirst("%pane-mode-changed ".count))
            return .paneModeChanged(paneId: paneId)
        } else if trimmed.hasPrefix("%exit") {
            let reason = trimmed.count > "%exit".count
                ? String(trimmed.dropFirst("%exit ".count))
                : nil
            return .exit(reason: reason)
        }

        return .unknown(line: line)
    }

    private func parseOutput(_ line: String) -> TmuxEvent {
        // %output %<pane-id> <data>
        let rest = String(line.dropFirst("%output ".count))
        guard let spaceIndex = rest.firstIndex(of: " ") else {
            return .unknown(line: line)
        }
        let paneId = String(rest[rest.startIndex..<spaceIndex])
        let data = String(rest[rest.index(after: spaceIndex)...])
        return .output(paneId: paneId, data: data)
    }

    private func parseSessionChanged(_ line: String) -> TmuxEvent {
        // %session-changed $<id> <name>
        let rest = String(line.dropFirst("%session-changed ".count))
        let parts = rest.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return .unknown(line: line) }
        return .sessionChanged(sessionId: String(parts[0]), name: String(parts[1]))
    }

    private func parseWindowRenamed(_ line: String) -> TmuxEvent {
        // %window-renamed @<id> <name>
        let rest = String(line.dropFirst("%window-renamed ".count))
        let parts = rest.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return .unknown(line: line) }
        return .windowRenamed(windowId: String(parts[0]), name: String(parts[1]))
    }

    private func parseLayoutChange(_ line: String) -> TmuxEvent {
        // %layout-change @<id> <layout-string>
        let rest = String(line.dropFirst("%layout-change ".count))
        let parts = rest.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return .unknown(line: line) }
        return .layoutChange(windowId: String(parts[0]), layout: String(parts[1]))
    }
}

/// Manages a tmux control mode session over an SSH channel
@MainActor
@Observable
final class TmuxControlModeClient {
    private(set) var sessions: [TmuxSession] = []
    private(set) var isConnected = false

    private let parser = TmuxControlModeParser()
    private var channel: SSHChannel?

    /// List tmux sessions on the remote host (pre-attach)
    func listSessions(via ssh: SSHClientProtocol) async throws -> [TmuxSession] {
        let output = try await ssh.execute("tmux list-sessions -F '#{session_id}:#{session_name}:#{session_windows}:#{session_created}:#{session_attached}'")
        return output
            .split(separator: "\n")
            .compactMap { parseTmuxListLine(String($0)) }
    }

    /// Attach to a session in control mode
    func attach(session: String, via ssh: SSHClientProtocol) async throws {
        let channel = try await ssh.openInteractiveChannel()
        self.channel = channel
        try await channel.write("tmux -CC attach -t \(session)\n".data(using: .utf8)!)
        isConnected = true

        // Process the event stream on the main actor
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await data in channel.outputStream {
                guard let text = String(data: data, encoding: .utf8) else { continue }
                for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                    let event = self.parser.parse(line: String(line))
                    self.handleEvent(event)
                }
            }
            self.isConnected = false
        }
    }

    /// Create a new tmux session
    func newSession(name: String, via ssh: SSHClientProtocol) async throws {
        _ = try await ssh.execute("tmux new-session -d -s \(name)")
    }

    /// Send keys to a specific pane
    func sendKeys(pane: String, keys: String) async throws {
        guard let channel else { return }
        let command = "send-keys -t \(pane) \(keys)\n"
        try await channel.write(command.data(using: .utf8)!)
    }

    private func handleEvent(_ event: TmuxEvent) {
        switch event {
        case .sessionChanged(_, let name):
            // Update current session context
            _ = name
        case .windowAdd(let windowId):
            _ = windowId
        case .windowRenamed(let windowId, let name):
            _ = (windowId, name)
        case .output(let paneId, let data):
            _ = (paneId, data)
        case .exit:
            isConnected = false
        default:
            break
        }
    }

    private func parseTmuxListLine(_ line: String) -> TmuxSession? {
        let parts = line.split(separator: ":", maxSplits: 4)
        guard parts.count >= 5 else { return nil }
        let id = String(parts[0])
        let name = String(parts[1])
        let windowCount = Int(parts[2]) ?? 0
        let created = Date(timeIntervalSince1970: TimeInterval(parts[3]) ?? 0)
        let attached = parts[4] == "1"
        return TmuxSession(
            id: id,
            name: name,
            windows: Array(repeating: TmuxWindow(id: "", name: "", index: 0, panes: [], isActive: false), count: windowCount),
            created: created,
            lastActivity: Date(),
            isAttached: attached
        )
    }
}
