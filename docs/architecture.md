# Architecture

## Overview

MobileMux is structured in four layers, each with clear responsibilities and
boundaries.

```
┌─────────────────────────────────────────────┐
│  Layer 4: Views (SwiftUI)                   │
│  Server list → Session list → Pane nav      │
├─────────────────────────────────────────────┤
│  Layer 3: Services                          │
│  ConnectionManager, KeychainService         │
├─────────────────────────────────────────────┤
│  Layer 2: Models                            │
│  ServerConnection (SwiftData, persisted)    │
│  TmuxSession/Window/Pane (runtime)          │
├─────────────────────────────────────────────┤
│  Layer 1: Transport                         │
│  SSHClient (Citadel), TmuxControlMode       │
└─────────────────────────────────────────────┘
```

## Layer 1: Transport

**SSHClient** — protocol-based SSH interface backed by Apple's swift-nio-ssh
directly. Supports:
- Password and SSH key authentication
- One-shot command execution (`tmux list-sessions`)
- Interactive shell channels (for `tmux -CC` control mode)

**TmuxControlMode** — parser and client for tmux's `-CC` control mode protocol.
Instead of rendering raw terminal escape sequences, control mode outputs
structured notifications (`%output`, `%window-add`, `%layout-change`, etc.)
that we parse into Swift events.

See [ssh-transport.md](ssh-transport.md) for SSH library evaluation and
transport design details.

## Layer 2: Models

Two categories:

**Persisted (SwiftData):**
- `ServerConnection` — saved server profiles (host, port, username, auth method).
  Credentials stored separately in iOS Keychain, referenced by tag.

**Runtime (in-memory):**
- `TmuxSession` — represents a tmux session with its windows and panes.
  Populated from tmux control mode events, not persisted.

## Layer 3: Services

- `ConnectionManager` — owns SSH connection lifecycle. Tracks active connections
  by server ID. Handles connect/disconnect/reconnect.
- `KeychainService` — CRUD for credentials in iOS Keychain. Passwords and
  private keys stored as `kSecClassGenericPassword` items, tagged by server UUID.

## Layer 4: Views

NavigationStack-based flow:
1. **ServerListView** — home screen, shows saved servers as cards
2. **SessionListView** — after connecting, shows active tmux sessions
3. **PaneNavigatorView** — pane cards with window tab bar, swipe navigation
4. **TerminalView** — full-screen terminal (SwiftTerm) for direct interaction

## Data Flow

```
User taps server
  → ConnectionManager.connect()
    → SSHClient.connect() + authenticate()
      → TmuxControlModeClient.listSessions()
        → SessionListView displays sessions

User taps session
  → TmuxControlModeClient.attach(session, via: ssh)
    → SSH interactive channel opened
    → tmux -CC output stream begins
    → TmuxControlModeParser emits events
    → PaneNavigatorView updates reactively via @Observable
```

## Concurrency Model

- SSH operations are async/await (swift-nio-ssh is SwiftNIO-based)
- tmux control mode runs a long-lived `Task` reading the channel's `AsyncStream`
- UI updates are dispatched to `@MainActor` via `@Observable`
- Connection state changes propagate through `ConnectionManager` (also `@Observable`)

## File Structure

```
MobileMux/
├── App/                    Entry point, root navigation
├── Models/                 Data models (persisted + runtime)
├── Transport/              SSH and tmux control mode
├── Views/
│   ├── Servers/            Server list, add/edit forms
│   ├── Sessions/           Session browser
│   ├── Panes/              Pane navigator and cards
│   └── Components/         Reusable UI components
└── Services/               Business logic and system services
```
