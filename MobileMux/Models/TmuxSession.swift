import Foundation

/// Runtime model representing a tmux session (not persisted — sourced from tmux)
struct TmuxSession: Identifiable {
    /// tmux session ID (e.g. "$0")
    let id: String
    let name: String
    var windows: [TmuxWindow]
    let created: Date
    var lastActivity: Date
    var isAttached: Bool

    var windowCount: Int { windows.count }
    var paneCount: Int { windows.reduce(0) { $0 + $1.panes.count } }
}

struct TmuxWindow: Identifiable {
    /// tmux window ID (e.g. "@0")
    let id: String
    let name: String
    let index: Int
    var panes: [TmuxPane]
    var isActive: Bool
}

struct TmuxPane: Identifiable {
    /// tmux pane ID (e.g. "%0")
    let id: String
    let width: Int
    let height: Int
    var currentCommand: String?
    /// Recent lines of output for preview cards
    var recentOutput: [String]
    var agentType: AgentType

    enum AgentType {
        case generic
        case claudeCode
    }
}
