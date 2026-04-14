# MobileMux

An iOS app for orchestrating AI agent sessions running in tmux on remote servers.

Not another terminal emulator — a purpose-built mobile interface that understands
tmux structure and the agents running inside it.

## What It Does

- **SSH into remote servers** with password or SSH key authentication
- **Browse tmux sessions** — see active sessions, create new ones
- **Navigate panes and windows** with swipe gestures and card-based UI instead
  of keyboard chords
- **Agent-aware rendering** — Claude Code sessions get rich status cards with
  approve/deny buttons instead of raw terminal output
- **Multi-server management** — save and switch between server connections

## How It Works

MobileMux uses tmux's **control mode** (`tmux -CC`) instead of rendering a
terminal emulator inside a terminal emulator. Control mode outputs structured
data about sessions, windows, and panes — letting MobileMux render each layer
as native iOS UI.

See [docs/tmux-control-mode.md](docs/tmux-control-mode.md) for protocol details.

## Tech Stack

| Component | Choice | Notes |
|-----------|--------|-------|
| Platform | iOS 18+ | iPhone-primary, iPad-supported |
| UI | SwiftUI | Swift 6, strict concurrency |
| SSH | [swift-nio-ssh](https://github.com/apple/swift-nio-ssh) | Apple-maintained, pure Swift, async-ready |
| Terminal | [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | ANSI rendering for full-screen pane view |
| Persistence | SwiftData | Server connection profiles |
| Credentials | iOS Keychain | Passwords and SSH private keys |

## Requirements

- iOS 18.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Setup

```bash
# Accept Xcode license (first time only)
sudo xcodebuild -license accept

# Install XcodeGen (nix-darwin users)
nix-shell -p xcodegen

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open MobileMux.xcodeproj
```

## Project Structure

```
MobileMux/
├── App/                    App entry point, root navigation
├── Models/
│   ├── ServerConnection    SwiftData model — saved server profiles
│   └── TmuxSession         Runtime models — session/window/pane hierarchy
├── Transport/
│   ├── SSHClient           SSH protocol + swift-nio-ssh implementation
│   └── TmuxControlMode     tmux -CC parser and control client
├── Views/
│   ├── Servers/            Server list, add/edit forms
│   ├── Sessions/           Session browser with cards
│   ├── Panes/              Pane navigator, window tab bar
│   └── Components/         Reusable UI (StatusBadge, etc.)
├── Services/
│   ├── ConnectionManager   SSH connection lifecycle
│   └── KeychainService     Credential storage
└── MobileMuxTests/         Unit tests
```

## Documentation

- [Architecture](docs/architecture.md) — layers, data flow, concurrency model
- [SSH Transport](docs/ssh-transport.md) — library evaluation, iOS considerations
- [tmux Control Mode](docs/tmux-control-mode.md) — protocol reference
- [Development Phases](docs/phases.md) — phased roadmap with checklists
- [Design](DESIGN.md) — UI wireframes and design principles

## Current Status

**Phase 1: Transport Validation** — project scaffolded, implementing SSH
transport layer with Citadel.

## License

GPL-3.0
