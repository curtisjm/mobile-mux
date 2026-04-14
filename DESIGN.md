# MobileMux — Design Document

## Vision

A mobile-first iOS app for orchestrating AI agent sessions running in tmux on
remote servers. Not another terminal emulator — a purpose-built interface that
understands tmux structure and (eventually) the agents running inside it.

## Target User

Developers running multi-agent workflows (Claude Code, Gas Town, or similar)
on remote servers who want to monitor, navigate, and interact from their phone
without fighting a tiny terminal.

## Platform

- iOS 18+ (SwiftUI, Swift 6)
- iPhone-primary, iPad-supported
- No Mac target (tmux is local on Mac — different UX problem)

## Core Concepts

### Connection → Session → Window → Pane

MobileMux maps directly to tmux's hierarchy but renders each level with
mobile-native UI instead of terminal escape sequences:

```
Server Connection (SSH)
  └── tmux Session ("gastown")
        ├── Window 0: "mayor" 
        │     └── Pane 0 [Claude Code — thinking]
        ├── Window 1: "refinery"
        │     └── Pane 0 [Claude Code — writing code]
        └── Window 2: "logs"
              ├── Pane 0 [tail -f app.log]
              └── Pane 1 [htop]
```

### tmux Control Mode (-CC)

The key technical differentiator. Instead of rendering tmux as a terminal app
inside a terminal emulator (inception-style), we use tmux's control mode:

```bash
tmux -CC attach -t mysession
```

Control mode outputs structured, parseable notifications:

```
%session-changed $1 main
%window-add @0
%window-renamed @0 mayor
%layout-change @0 a]80x24,0,0,0
%output %0 Claude is thinking...
%begin 1234567890 1 0
%end 1234567890 1 0
```

This lets MobileMux know the full tmux state — sessions, windows, panes, and
their content — without parsing ANSI escape sequences for layout information.

Each pane's content still arrives as terminal output that needs rendering, but
the *structure* is known programmatically.

---

## UI Design

### Design Principles

1. **Cards over characters**: Show session/pane state as rich cards, not raw text
2. **Swipe over chords**: Navigate with gestures, not `Ctrl-b` sequences
3. **Status at a glance**: Surface what matters without full-screen terminal views
4. **Terminal when needed**: Full terminal rendering available but not the default
5. **Dark mode native**: Matches the terminal-adjacent aesthetic without being a
   black-and-green retro cosplay

### Screen Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │
│   Servers    │────▶│   Sessions   │────▶│    Panes     │
│   (home)     │     │   (per host) │     │  (per window)│
│              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
                                                ▼
                                          ┌──────────────┐
                                          │   Terminal    │
                                          │  (full pane)  │
                                          └──────────────┘
```

### 1. Server List (Home)

The app opens here. Shows saved server connections as cards.

```
┌─────────────────────────────────┐
│  MobileMux                    + │
│─────────────────────────────────│
│  ┌─────────────────────────────┐│
│  │ 🟢 dev-server              ││
│  │ curtis@dev.example.com     ││
│  │ 3 sessions · connected     ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ ⚫ production              ││
│  │ deploy@prod.example.com    ││
│  │ last: 2h ago               ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ ⚫ home-lab                ││
│  │ curtis@192.168.1.50        ││
│  │ last: 1d ago               ││
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

Each card shows:
- Connection status indicator (green = connected, gray = disconnected)
- Server nickname
- User@host
- Active session count (when connected) or last-connected time

**Add Server** form collects: nickname, host, port, username, auth method
(password or SSH key), and optional key file.

### 2. Session List (per server)

After connecting, shows active tmux sessions. Option to create a new one.

```
┌─────────────────────────────────┐
│  ◀ dev-server          New +    │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────────┐│
│  │ gastown                     ││
│  │ 5 windows · 12 panes       ││
│  │ created 3h ago · active     ││
│  │                             ││
│  │ mayor ∘ refinery ∘ polecat1 ││
│  │ polecat2 ∘ logs             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ dev                         ││
│  │ 2 windows · 2 panes        ││
│  │ created 1d ago · idle 4h   ││
│  │                             ││
│  │ editor ∘ shell              ││
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

Each session card shows:
- Session name
- Window/pane count
- Age and activity recency
- Window name pills as a preview

### 3. Pane Navigator (attached to session)

The main interaction screen. Shows the current window's panes with a
window tab bar at the bottom.

**Single-pane window** — shows the pane content as a card with a preview
of recent output. Tap to go full-screen terminal.

**Multi-pane window** — shows panes stacked vertically as cards (not
trying to replicate tmux's split layout on a phone screen).

```
┌─────────────────────────────────┐
│  ◀ gastown                  ⚙   │
│─────────────────────────────────│
│  ┌─────────────────────────────┐│
│  │ Pane 0                      ││
│  │                             ││
│  │  $ gt mol status            ││
│  │  🪝 Hook: mayor/            ││
│  │  No molecule attached       ││
│  │                             ││
│  │  ▸ Tap to interact          ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Pane 1                      ││
│  │                             ││
│  │  tail -f app.log            ││
│  │  [17:23] Request handled    ││
│  │  [17:23] 200 OK /api/health ││
│  │                             ││
│  │  ▸ Tap to interact          ││
│  └─────────────────────────────┘│
│                                 │
│  ┌───┬───┬───┬───┬───┐         │
│  │may│ref│pc1│pc2│log│         │
│  └───┴───┴───┴───┴───┘         │
└─────────────────────────────────┘
```

Window tab bar is scrollable. Active tab is highlighted. Swipe left/right
on the content area to switch windows.

### 4. Full Terminal View

Tapping a pane card opens a full-screen terminal for direct interaction.
Uses a proper terminal emulator (SwiftTerm or similar) for ANSI rendering.

Includes a smart toolbar above the keyboard with:
- Common tmux keys (Ctrl-C, Ctrl-D, arrow keys)
- Quick-escape button to return to pane navigator
- (Future) Agent-specific action buttons

### 5. Agent-Aware Pane Cards (Phase 3)

When a pane is detected as running Claude Code (or similar), the card
renders differently:

```
┌─────────────────────────────────┐
│ 🤖 Claude Code          ● Live  │
│─────────────────────────────────│
│                                 │
│ Status: Writing code            │
│ File: src/api/routes.ts         │
│                                 │
│ "Adding validation to the       │
│  signup endpoint..."            │
│                                 │
│ ┌─────────┐ ┌─────────┐        │
│ │ Approve │ │  Deny   │        │
│ └─────────┘ └─────────┘        │
└─────────────────────────────────┘
```

---

## Architecture

### Layer 1: Transport (SSH + Control Mode)

```
SSHClient
  ├── connect(host, port, credentials) → SSHConnection
  ├── authenticate(password | key)
  ├── execute(command) → String          // one-shot commands
  └── openChannel() → SSHChannel         // interactive channel

TmuxControlModeClient
  ├── attach(session) → TmuxControlStream
  ├── listSessions() → [TmuxSession]     // via `tmux list-sessions`
  ├── newSession(name) → TmuxSession
  └── sendKeys(pane, keys)

TmuxControlStream (parses -CC output)
  ├── onSessionChanged((Session) -> Void)
  ├── onWindowAdd((Window) -> Void)
  ├── onWindowRenamed((Window, String) -> Void)
  ├── onLayoutChange((Window, Layout) -> Void)
  ├── onOutput((Pane, String) -> Void)
  └── onPaneModeChanged((Pane, Mode) -> Void)
```

### Layer 2: Models

```swift
// Persisted (SwiftData)
ServerConnection
  - id: UUID
  - nickname: String
  - host: String
  - port: Int
  - username: String
  - authMethod: AuthMethod (.password | .key)
  - keyTag: String?           // Keychain reference
  - lastConnected: Date?

// Runtime (in-memory, from tmux)
TmuxSession
  - id: String                // tmux session ID ($0, $1, ...)
  - name: String
  - windows: [TmuxWindow]
  - created: Date
  - lastActivity: Date

TmuxWindow
  - id: String                // @0, @1, ...
  - name: String
  - index: Int
  - panes: [TmuxPane]
  - isActive: Bool

TmuxPane
  - id: String                // %0, %1, ...
  - width: Int
  - height: Int
  - outputBuffer: TerminalBuffer
  - agentType: AgentType?     // .claudeCode | .generic | nil
```

### Layer 3: Services

```
ConnectionManager
  - Manages SSH connection lifecycle
  - Reconnection logic
  - Multiplexes channels per connection

KeychainService
  - Stores passwords and SSH private keys
  - Uses iOS Keychain Services API

AgentDetector
  - Analyzes pane output to classify agent type
  - Pattern matching for Claude Code prompts, status lines, etc.
```

### Layer 4: Views (SwiftUI)

NavigationStack-based flow:
```
ServerListView → SessionListView → PaneNavigatorView → TerminalView
```

---

## Dependencies

| Dependency | Purpose | Notes |
|------------|---------|-------|
| [swift-nio-ssh](https://github.com/apple/swift-nio-ssh) | SSH transport | Apple-maintained, pure Swift, used by SwiftTerm on iOS |
| [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | Terminal emulation | iOS-compatible, handles ANSI rendering |
| SwiftData | Server connection persistence | Built-in, iOS 17+ |
| Security.framework | Credential storage | iOS Keychain via system API |

---

## Phased Plan

### Phase 1: Transport Validation
- [ ] SSH connection with password and key auth
- [ ] Execute commands over SSH
- [ ] tmux control mode attachment and basic parsing
- [ ] Enumerate sessions, windows, panes via control mode
- **Goal**: Prove the transport layer works reliably on iOS

### Phase 2: Session Navigator
- [ ] Server list with SwiftData persistence
- [ ] Add/edit/delete server connections
- [ ] Credential storage in Keychain
- [ ] Session list after connecting
- [ ] Create new tmux session
- [ ] Pane navigator with card-based layout
- [ ] Window tab bar with swipe navigation
- **Goal**: Navigate tmux without typing tmux commands

### Phase 3: Terminal Interaction
- [ ] Integrate SwiftTerm for full pane rendering
- [ ] Smart keyboard toolbar (common keys, Ctrl combos)
- [ ] Send keystrokes to tmux panes
- [ ] Handle terminal resize events
- **Goal**: Fully interactive tmux on mobile with better UX

### Phase 4: Agent Awareness
- [ ] Detect Claude Code sessions from output patterns
- [ ] Agent-specific card rendering (status, current file, etc.)
- [ ] Quick-action buttons (approve/deny tool calls)
- [ ] Push notifications when agent needs input
- **Goal**: Purpose-built AI agent monitoring, not just a terminal

### Phase 5: Polish & iPad
- [ ] iPad layout with sidebar + detail split view
- [ ] Connection health monitoring and auto-reconnect
- [ ] Background SSH keep-alive
- [ ] Haptic feedback for agent state changes
- [ ] Widget for home screen status glances
