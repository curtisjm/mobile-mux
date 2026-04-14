# tmux Control Mode Protocol

## Overview

tmux's control mode (`tmux -CC`) is the foundation of MobileMux. Instead of
rendering terminal escape sequences into a grid (what every other SSH app does),
control mode outputs structured, parseable notifications about tmux state.

This lets MobileMux render each pane as a native SwiftUI card rather than a
miniature terminal grid.

## Entering Control Mode

```bash
# Attach to existing session
tmux -CC attach -t <session-name>

# Create new session in control mode
tmux -CC new-session -s <session-name>
```

## Notification Format

All notifications are prefixed with `%`:

### Session Events
```
%session-changed $<id> <name>    # Switched to a different session
%session-renamed <name>          # Current session was renamed
%sessions-changed                # Session list changed (created/destroyed)
```

### Window Events
```
%window-add @<id>                # Window created
%window-close @<id>              # Window destroyed
%window-renamed @<id> <name>     # Window renamed
%window-pane-changed @<id> %<pane-id>  # Active pane changed in window
```

### Pane Events
```
%output %<pane-id> <data>        # Output from a pane (the main data stream)
%pane-mode-changed %<pane-id>    # Pane entered/exited copy mode etc.
```

### Layout Events
```
%layout-change @<id> <layout>    # Window layout changed (pane split/resize)
```

Layout strings encode the pane arrangement:
```
# Single pane, 80x24
a]80x24,0,0,0

# Two horizontal panes
b]80x24,0,0{40x24,0,0,0,40x24,41,0,1}

# Two vertical panes
c]80x24,0,0[80x12,0,0,0,80x11,0,13,1]
```

### Command Responses
```
%begin <time> <cmd-num> <flags>  # Start of command response
<response data>                   # The actual response
%end <time> <cmd-num> <flags>    # End of command response
%error <time> <cmd-num> <flags>  # Command error
```

### Exit
```
%exit                            # Clean exit
%exit <reason>                   # Exit with reason (e.g., "server exited")
```

## Sending Commands

Commands are sent as plain text lines through the control channel:

```
list-windows                     # List windows in current session
list-panes -t @0                 # List panes in window @0
send-keys -t %0 "hello" Enter    # Type "hello" + Enter in pane %0
select-window -t @1              # Switch to window @1
resize-pane -t %0 -x 80 -y 24   # Resize pane
```

## Pane Output

The `%output` notification delivers raw terminal output from panes. This still
contains ANSI escape sequences for colors, cursor movement, etc. MobileMux
handles this in two ways:

1. **Preview mode** (pane cards): Strip ANSI, show last N lines as plain text
2. **Terminal mode** (full screen): Pass to SwiftTerm for full rendering

## Implementation Notes

### Identifiers
- Sessions: `$0`, `$1`, etc.
- Windows: `@0`, `@1`, etc.
- Panes: `%0`, `%1`, etc.

### Escaping
Data in `%output` uses C-style escaping for special characters:
- `\n` for newline
- `\\` for backslash
- `\033` for ESC (start of ANSI sequences)

### Reconnection
tmux preserves all session state server-side. If the SSH connection drops:
1. The control mode stream ends
2. Re-establish SSH connection
3. Re-attach with `tmux -CC attach -t <session>`
4. tmux sends full state re-sync (all windows, panes, layout)

This is a major advantage — MobileMux never needs to persist tmux state locally.

## References

- `man tmux` — search for "CONTROL MODE"
- tmux source: `control.c`, `control-notify.c`
- iTerm2's tmux integration (uses the same protocol)
