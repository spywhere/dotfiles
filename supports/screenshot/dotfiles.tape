# Recreates the README setup screenshot from the real dotfiles configs.
#
# Assumes install.sh has already linked the configs, and ~/.explist has
# tmux=a (disables zshrc's auto-launch race -- it starts herdr while zinit
# is still finishing its first-run plugin bootstrap on a fresh shell, which
# is unpredictably slow in CI, so herdr is launched explicitly below
# instead). lua-language-server, tree-sitter and opencode must already be
# on PATH (see .github/workflows/screenshot.yml).
#
# herdr's own CLI (tab create/rename --json) turned out not to support
# --json on this install ("unknown option"), so tab setup below goes
# through plain keybindings instead. previous_tab/next_tab are shift+left/
# right per config.toml, which vhs's tape parser can't send at all
# ("Expected shift character, got +") -- prefix+<N> jump-to-tab-by-number
# works fine though, so that's used to get back to tab 1 instead.
#
# Run from the repo root: vhs supports/screenshot/dotfiles.tape
# (renders into .github/screenshot/preview.png, alongside the workflow
# that runs this -- README.md embeds it from there)

Output "dotfiles-screenshot.gif"

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 2200
Set Height 1200
Set Padding 0
Set WindowBar "Colorful"
Set WindowBarSize 40

# Same ANSI palette as configs/kitty/kitty.conf and configs/ghostty/config
# (they agree exactly on background/foreground/cursor/selection) -- so
# whatever tty-clock's -C flag resolves to should match the real setup's
# colors, not vhs's own default theme.
Set Theme {"name":"dotfiles","black":"#3b4252","red":"#bf616a","green":"#a3be8c","yellow":"#ebcb8b","blue":"#8aa1c1","magenta":"#b48ead","cyan":"#99c0d0","white":"#e5e9f0","brightBlack":"#4c566a","brightRed":"#bf616a","brightGreen":"#a3be8c","brightYellow":"#ebcb8b","brightBlue":"#81a1c1","brightMagenta":"#b48ead","brightCyan":"#8fbcbb","brightWhite":"#eceff4","background":"#1c1c1c","foreground":"#d8dee9","selection":"#4c566a","cursor":"#d8dee9"}

# Let zsh/zinit finish its first-run bootstrap before typing anything
Sleep 10s

Type "herdr"
Enter
Sleep 3s

# Open the sidebar (starts collapsed/hidden per configs/herdr/config.toml).
# Do this once up front so it stays open across both tabs below.
Ctrl+A
Type "b"
Sleep 500ms

# Name tab 1 (rename_tab is prefix+shift+t; Ctrl+U clears any pre-filled
# text in the rename prompt before typing the new name).
Ctrl+A
Type "T"
Sleep 500ms
Ctrl+U
Type "neovim"
Enter
Sleep 500ms

# Split off a clock pane on the right (herdr prefix is ctrl+a, per config.toml)
# -c centers the clock in the pane. tty-clock only supports the 8 basic
# ANSI colors via -C (no truecolor/hex), so -C 4 (blue) is resolved against
# the Set Theme palette above.
Ctrl+A
Type "|"
Sleep 500ms
Type "tty-clock -c -C 4"
Enter
Sleep 500ms

# Split that pane again for fastfetch (neofetch's successor -- neofetch was
# dropped from homebrew-core after being archived upstream)
Ctrl+A
Type "-"
Sleep 500ms
Type "clear && fastfetch"
Enter
Sleep 2s

# Back to the main (left) pane
Ctrl+A
Type "h"
Sleep 500ms

# Open both files the same way the original screenshot shows them: lsp.lua
# loaded first, then plugin-manager.lua opened on top of it as the active
# buffer (so the tab bar shows both, with plugin-manager.lua focused).
Type "nvim configs/nvim/lua/lib/lsp.lua"
Enter
Sleep 4s

Type ":e configs/nvim/lua/lib/plugin-manager.lua"
Enter
Sleep 2s

# Create the agent tab now (prefix+c, auto-focused) -- nvim/LSP keep
# settling in the background on tab 1 while this happens, then prefix+1
# jumps back to it right before the completion demo and screenshot.
Ctrl+A
Type "c"
Sleep 1s

Ctrl+A
Type "T"
Sleep 500ms
Ctrl+U
Type "opencode"
Enter
Sleep 500ms

Type "opencode"
Enter
Sleep 3s

Ctrl+A
Type "1"
Sleep 500ms

# Demo autocomplete: search for the M.setup local (rather than a hardcoded
# line number, so this keeps working if the file changes), open a new line
# below it, and type "pl" -- plug_nvim_path, plugin_home and plug_nvim_url
# are still real globals from lib/const.lua, so this should surface the
# same completion candidates the original screenshot showed.
Type "/local plug = require"
Enter
Sleep 300ms
Type "opl"
Sleep 1500ms

Screenshot ".github/screenshot/preview.png"
