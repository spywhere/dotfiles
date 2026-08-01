# Recreates the README setup screenshot from the real dotfiles configs.
#
# Assumes install.sh has already linked the configs, ~/.explist has
# explorer=tree and herdr=b (so the shell auto-launches herdr with the
# nvim-tree explorer enabled, matching the original screenshot), and
# HERDR_CONFIG_PATH points at configs/herdr/config.toml plus
# statusbar-overlay.toml. See .github/workflows/screenshot.yml.
#
# Run from the repo root: vhs supports/screenshot/dotfiles.tape

Output /tmp/dotfiles-screenshot.gif

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 12
Set Width 2000
Set Height 1200
Set Padding 0
Set WindowBar "Colorful"
Set WindowBarSize 40

# Let zsh/zinit start up and auto-launch herdr
Sleep 5s

Type "nvim configs/nvim/lua/lib/plugin-manager.lua"
Enter
Sleep 3s
Type ",e"
Sleep 1s

# Split off a clock pane on the right (herdr prefix is ctrl+a, per config.toml)
Ctrl+A
Type "|"
Sleep 500ms
Type "tty-clock -c"
Enter
Sleep 500ms

# Split that pane again for neofetch
Ctrl+A
Type "-"
Sleep 500ms
Type "neofetch"
Enter
Sleep 2s

Screenshot supports/screenshot/preview.png
