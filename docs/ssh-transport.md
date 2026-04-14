# SSH Transport — Library Evaluation

## Decision: swift-nio-ssh (Apple)

We use [swift-nio-ssh](https://github.com/apple/swift-nio-ssh) directly as the
SSH transport layer.

## Why swift-nio-ssh

- **Apple-maintained** — no single-maintainer risk, follows Swift release cadence
- **One dependency, not two** — Citadel wraps swift-nio-ssh, so using it adds a
  layer without removing the underlying dependency
- **More control** — the tmux -CC channel is the core of MobileMux. We want to
  own the channel handling, not debug through a wrapper when something breaks
- **Narrow needs** — MobileMux needs three SSH operations: connect+auth, exec a
  command, open an interactive channel. That's a small surface to wrap ourselves.
- **Proven on iOS** — SwiftTerm's `UIKitSshTerminalView.swift` demonstrates
  interactive SSH on iOS using this exact library
- **Pure Swift** — no C bridging, built on SwiftNIO + swift-crypto
- **Async-ready** — SwiftNIO integrates with Swift concurrency

## Reference Implementation

SwiftTerm's iOS SSH terminal view is the best reference for wrapping
swift-nio-ssh for interactive use on iOS. It handles:
- Connection and authentication (password + key)
- PTY channel setup
- Bidirectional data streaming
- Terminal resize events

## Alternatives Evaluated

| Library | Status | Why not |
|---------|--------|---------|
| **Citadel** | Active, 355 stars | Convenience wrapper over swift-nio-ssh. Adds SFTP, SCP, and higher-level APIs we don't need. One more dependency + one more maintainer to track for ~200 lines of saved boilerplate. |
| **NMSSH** | Unmaintained (last: Mar 2024) | Obj-C, wraps libssh2, 104 open issues, no Swift concurrency |
| **Shout** | Low activity (last: Jun 2024) | Exec-only, no interactive shell channels, no iOS support |
| **SwiftSH** | Abandoned (last: Nov 2021) | Wraps libssh2, 30 open issues, dead |
| **libssh2 direct** | Viable but painful | Compile C for iOS, write bridging, manual concurrency |

## Custom SSH Library — Not Worth It

Building SSH from scratch requires implementing RFCs 4251-4254: key exchange,
packet framing, MAC verification, channel multiplexing, cipher suites.
Realistic estimate: **6-12 months** for one experienced developer to reach
production quality. Apple already did this work with swift-nio-ssh.

## iOS-Specific Considerations

### Background Execution

iOS suspends apps ~30 seconds after backgrounding. Long-lived SSH connections
(like our tmux -CC channel) will drop. Options:
- **BGTaskScheduler** — limited, not designed for sustained connections
- **Network Extension entitlement** — proper solution for sustained networking
- **Reconnect-on-foreground** — simplest MVP approach. Detect disconnection,
  re-attach to tmux session (tmux preserves state server-side)

For Phase 1, we use reconnect-on-foreground. Background keep-alive is a Phase 5
concern.

### App Store

No restrictions on outbound SSH — Termius, Prompt, and Blink all ship on the
App Store with SSH.

### Localhost

iOS blocks App Store apps from connecting to localhost:22. Not relevant for
MobileMux (we connect to remote servers).

## Integration

```yaml
# project.yml
packages:
  swift-nio-ssh:
    url: https://github.com/apple/swift-nio-ssh
    from: "0.12.0"
```

The `SSHClient.swift` protocol is already defined. Implementation will wrap
swift-nio-ssh's types, using SwiftTerm's iOS SSH code as a reference.
