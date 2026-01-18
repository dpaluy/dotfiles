# Ghostty Configuration

Terminal emulator config for [Ghostty](https://ghostty.org/).

## Files

- `config` - Main configuration (symlinked to `~/.config/ghostty/config`)
- `~/.local/dotfiles/ghostty.local` - Machine-specific overrides (font size, theme)

## SSH to Remote Machines (Terminfo)

Ghostty uses the Kitty keyboard protocol for enhanced input handling. Remote machines don't have the `xterm-ghostty` terminfo by default, which causes garbage output like `[57414u` when pressing certain keys.

### Fix: Install terminfo on remote servers

Run this **from your Mac** for each server you SSH into:

```bash
ghostty-terminfo user@server
```

This pushes Ghostty's terminfo definition to the remote machine.

### Manual method

```bash
infocmp -x xterm-ghostty | ssh user@server 'mkdir -p ~/.terminfo && tic -x -o ~/.terminfo -'
```

### Verify installation

```bash
ssh user@server 'ls ~/.terminfo/x/xterm-ghostty'
```

### Fallback (no terminfo install)

If you can't install terminfo on a server, force a compatible TERM:

```bash
TERM=xterm-256color ssh user@server
```

This loses Ghostty-specific features but avoids the garbage output.

### Troubleshooting

- **`tic` not found**: Install `ncurses-bin` on the remote (Debian/Ubuntu) or `ncurses` (RHEL/Fedora)
- **Permission denied**: Ensure `~/.terminfo` is writable by your user
- **Still seeing garbage**: Verify `echo $TERM` shows `xterm-ghostty` after connecting
