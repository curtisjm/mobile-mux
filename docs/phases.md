# Development Phases

## Phase 1: Transport Validation

Prove the SSH + tmux control mode stack works on iOS.

- [ ] Add Citadel as SPM dependency
- [ ] Implement `SSHClientProtocol` wrapping Citadel
- [ ] Password authentication
- [ ] SSH key authentication
- [ ] One-shot command execution
- [ ] Interactive shell channel with PTY
- [ ] Connect to a real server, run `tmux -CC attach`, parse events
- [ ] Unit tests for `TmuxControlModeParser`

**Exit criteria**: App connects to a server, lists tmux sessions, attaches in
control mode, and logs parsed events to console.

## Phase 2: Session Navigator

Build the core navigation UI.

- [ ] Server list with SwiftData persistence
- [ ] Add/edit/delete server connections
- [ ] Credential storage in Keychain (password + key)
- [ ] SSH key import from Files app
- [ ] Connect to server and display session list
- [ ] Create new tmux session
- [ ] Session cards with window/pane counts
- [ ] Pane navigator with card-based layout
- [ ] Window tab bar with active indicator
- [ ] Swipe between windows

**Exit criteria**: Full navigation flow from server list to pane cards, with
real data from a tmux server.

## Phase 3: Terminal Interaction

Make panes interactive.

- [ ] Integrate SwiftTerm for full-screen terminal rendering
- [ ] Route pane output to SwiftTerm
- [ ] Send keystrokes from SwiftTerm to tmux pane
- [ ] Smart keyboard toolbar (Ctrl-C, Ctrl-D, arrows, Tab, Esc)
- [ ] Handle terminal resize events
- [ ] Reconnect-on-foreground when SSH drops

**Exit criteria**: Can fully interact with any tmux pane as if using a
terminal, but with better navigation between panes/windows.

## Phase 4: Agent Awareness

The differentiating feature — detect and enhance AI agent sessions.

- [ ] Output pattern matching for Claude Code sessions
- [ ] Agent-specific pane cards (status, current file, activity)
- [ ] Quick-action buttons (approve/deny for tool calls)
- [ ] Status badges (thinking, writing, waiting, running command)
- [ ] Agent activity summary in session cards
- [ ] Push notifications when agent needs input

**Exit criteria**: Claude Code panes render with rich status cards and
actionable buttons instead of raw terminal output.

## Phase 5: Polish & iPad

Production readiness and expanded platform support.

- [ ] iPad layout — sidebar + detail split view
- [ ] Auto-reconnect with exponential backoff
- [ ] Background connection keep-alive (Network Extension or BGTask)
- [ ] Haptic feedback for agent state changes
- [ ] Home screen widget for agent status at a glance
- [ ] Server connection health monitoring
- [ ] Onboarding flow for first-time users
- [ ] App Store submission
