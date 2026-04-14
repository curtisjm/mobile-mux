import Foundation

/// Mock data for SwiftUI previews — keeps preview providers clean
enum PreviewData {
    static let sessions: [TmuxSession] = [
        TmuxSession(
            id: "$0",
            name: "gastown",
            windows: [
                TmuxWindow(
                    id: "@0", name: "mayor", index: 0,
                    panes: [
                        TmuxPane(
                            id: "%0", width: 80, height: 24,
                            currentCommand: "claude",
                            recentOutput: [
                                "$ gt mol status",
                                "Hook: mayor/",
                                "Hooked: hq-6c4e: HANDOFF",
                                "No molecule attached",
                            ],
                            agentType: .claudeCode
                        ),
                    ],
                    isActive: true
                ),
                TmuxWindow(
                    id: "@1", name: "refinery", index: 1,
                    panes: [
                        TmuxPane(
                            id: "%1", width: 80, height: 24,
                            currentCommand: "claude",
                            recentOutput: [
                                "Reviewing PR #42...",
                                "Status: Writing code",
                                "File: src/api/routes.ts",
                            ],
                            agentType: .claudeCode
                        ),
                    ],
                    isActive: false
                ),
                TmuxWindow(
                    id: "@2", name: "polecat-1", index: 2,
                    panes: [
                        TmuxPane(
                            id: "%2", width: 80, height: 24,
                            currentCommand: "claude",
                            recentOutput: [
                                "Running tests...",
                                "  42 passed",
                                "  0 failed",
                                "All tests passed.",
                            ],
                            agentType: .claudeCode
                        ),
                    ],
                    isActive: false
                ),
                TmuxWindow(
                    id: "@3", name: "logs", index: 3,
                    panes: [
                        TmuxPane(
                            id: "%3", width: 80, height: 12,
                            currentCommand: "tail -f app.log",
                            recentOutput: [
                                "[17:23:01] GET /api/health 200 2ms",
                                "[17:23:05] POST /api/auth 201 45ms",
                                "[17:23:12] GET /api/users 200 12ms",
                            ],
                            agentType: .generic
                        ),
                        TmuxPane(
                            id: "%4", width: 80, height: 12,
                            currentCommand: "htop",
                            recentOutput: [
                                "CPU: 23%  MEM: 4.2G/16G",
                                "Load: 1.2 0.8 0.6",
                                "Tasks: 142 running",
                            ],
                            agentType: .generic
                        ),
                    ],
                    isActive: false
                ),
            ],
            created: Date().addingTimeInterval(-3600 * 3),
            lastActivity: Date().addingTimeInterval(-60),
            isAttached: true
        ),
        TmuxSession(
            id: "$1",
            name: "dev",
            windows: [
                TmuxWindow(
                    id: "@4", name: "editor", index: 0,
                    panes: [
                        TmuxPane(
                            id: "%5", width: 80, height: 24,
                            currentCommand: "nvim",
                            recentOutput: ["~", "~", "~", "-- INSERT --"],
                            agentType: .generic
                        ),
                    ],
                    isActive: true
                ),
                TmuxWindow(
                    id: "@5", name: "shell", index: 1,
                    panes: [
                        TmuxPane(
                            id: "%6", width: 80, height: 24,
                            currentCommand: "zsh",
                            recentOutput: ["$ "],
                            agentType: .generic
                        ),
                    ],
                    isActive: false
                ),
            ],
            created: Date().addingTimeInterval(-3600 * 24),
            lastActivity: Date().addingTimeInterval(-3600 * 4),
            isAttached: false
        ),
    ]
}
