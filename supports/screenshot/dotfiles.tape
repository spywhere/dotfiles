# Recreates the README setup screenshot from the real dotfiles configs.
#
# Assumes install.sh has already linked the configs, ~/.explist has
# explorer=tree (nvim-tree enabled) and tmux=a (disables zshrc's
# auto-launch race -- it starts herdr while zinit is still finishing its
# first-run plugin bootstrap on a fresh shell, which is unpredictably slow
# in CI, so herdr is launched explicitly below instead), and
# HERDR_CONFIG_PATH points at configs/herdr/config.toml plus
# statusbar-overlay.toml. lua-language-server must already be on PATH (see
# .github/workflows/screenshot.yml) since configs/nvim's lua_ls setup only
# attaches if the binary already exists, it doesn't auto-install one.
#
# Run from the repo root: vhs supports/screenshot/dotfiles.tape

Output "dotfiles-screenshot.gif"

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 12
Set Width 2200
Set Height 1200
Set Padding 0
Set WindowBar "Colorful"
Set WindowBarSize 40

# Let zsh/zinit finish its first-run bootstrap before typing anything
Sleep 10s

Type "herdr"
Enter
Sleep 3s

# Open the sidebar (starts collapsed/hidden per configs/herdr/config.toml)
Ctrl+A
Type "b"
Sleep 500ms

# Set up the surrounding panes first, then come back to the main pane last
# so nvim/LSP get the most time to fully start up before the screenshot.

# Split off a clock pane on the right (herdr prefix is ctrl+a, per config.toml)
Ctrl+A
Type "|"
Sleep 500ms
Type "tty-clock -c"
Enter
Sleep 500ms

# Split that pane again for fastfetch (neofetch's successor -- neofetch was
# dropped from homebrew-core after being archived upstream)
Ctrl+A
Type "-"
Sleep 500ms
Type "fastfetch"
Enter
Sleep 2s

# Back to the main (left) pane
Ctrl+A
Type "h"
Sleep 500ms

Type "nvim configs/nvim/lua/lib/plugin-manager.lua"
Enter
Sleep 5s

Type ",e"
Sleep 1s

# nvim-tree grabs focus on toggle -- move back to the buffer window
Ctrl+W
Type "l"
Sleep 300ms

# Demo the LSP: jump into a real vim.fn call and trigger signature help
Type "/vim.fn.expand"
Enter
Sleep 300ms
Type "f("
Type ":lua vim.lsp.buf.signature_help()"
Enter
Sleep 2s

Screenshot "supports/screenshot/preview.png"
