# Recreates the README setup screenshot from the real dotfiles configs.
#
# Assumes install.sh has already linked the configs, and ~/.explist has
# tmux=a (disables zshrc's auto-launch race -- it starts herdr while zinit
# is still finishing its first-run plugin bootstrap on a fresh shell, which
# is unpredictably slow in CI, so herdr is launched explicitly below
# instead). lua-language-server and opencode must already be on PATH (see
# .github/workflows/screenshot.yml) since configs/nvim's lua_ls setup only
# attaches if the binary already exists, it doesn't auto-install one.
#
# Run from the repo root: vhs supports/screenshot/dotfiles.tape

Output "dotfiles-screenshot.gif"

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 15
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
# -C 6 is tty-clock's own color flag (cyan) -- independent of the terminal
# palette, -c just centers the clock in the pane.
Ctrl+A
Type "|"
Sleep 500ms
Type "tty-clock -c -C 6"
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

# Split once more for an agent pane
Ctrl+A
Type "-"
Sleep 500ms
Type "opencode"
Enter
Sleep 3s

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

# Demo autocomplete instead of signature help: jump into the vim-plug
# branch of proxy_map and type "pl" -- plug_nvim_path, plugin_home and
# plug_nvim_url are still real globals from lib/const.lua, so this should
# surface the same completion candidates the original screenshot showed.
Type "/if backend == 'vim-plug'"
Enter
Sleep 300ms
Type "jjo"
Sleep 300ms
Type "pl"
Sleep 1500ms

Screenshot "supports/screenshot/preview.png"
