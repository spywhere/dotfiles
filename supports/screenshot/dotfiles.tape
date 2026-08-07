# Records the README demo (.github/demo.gif) from the real dotfiles
# configs, driving one herdr/nvim session for the whole take.
#
# The tape can also freeze its own last frame as a still screenshot -- see
# the commented-out Screenshot at the bottom. The README carries just the
# demo for now, so that stays off; keeping it here (rather than deleting
# it) is what keeps the two in sync if the still comes back, since a
# screenshot taken by this tape is by construction the same state the
# recording ends on.
#
# Assumes install.sh has already linked the configs from this checkout,
# and ~/.explist has tmux=a and no_wakatime=b (see
# .github/workflows/screenshot.yml for why both matter). fzf, fd, ripgrep,
# lua-language-server, the tree-sitter CLI and opencode must already be on
# PATH.
#
# herdr's own CLI (tab create/rename --json) turned out not to support
# --json on this install ("unknown option"), so tab setup below goes
# through plain keybindings instead. previous_tab/next_tab are shift+left/
# right per config.toml, which vhs's tape parser can't send at all
# ("Expected shift character, got +") -- prefix+<N> jump-to-tab-by-number
# works fine though, so that's used to get back to tab 1 instead.
#
# Everything up to nvim sitting on the Alpha splash screen is bracketed by
# Hide/Show: it still runs for real, so the final frame shows the full
# 3-pane/2-tab layout, it just isn't part of the take. Note vhs needs at
# least one visible frame or it exits with "no frames / recording failed",
# so Show must stay ahead of the last Sleep.
#
# Typing speed: after Show, every Type is speed-tagged (Type@Nms) rather
# than left at vhs's flat default, so it reads like a person typing rather
# than text appearing at once -- brisk for keys typed from muscle memory,
# slower for the search and completion beats the demo is actually about.
# Longer strings are split across calls with a short Sleep between chunks
# to mimic the small hesitations real typing has. Nothing before Show is
# tagged, since none of it is on camera.
#
# Run from the repo root: vhs supports/screenshot/dotfiles.tape

Output ".github/demo.gif"

Set Shell "zsh"
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 2200
Set Height 1200
Set Padding 0
Set WindowBar "Colorful"
Set WindowBarSize 40
Set Framerate 24
Set TypingSpeed 60ms

# Same ANSI palette as configs/kitty/kitty.conf and configs/ghostty/config
# (they agree exactly on background/foreground/cursor/selection) -- so
# whatever tty-clock's -C flag resolves to should match the real setup's
# colors, not vhs's own default theme.
Set Theme {"name":"dotfiles","black":"#3b4252","red":"#bf616a","green":"#a3be8c","yellow":"#ebcb8b","blue":"#8aa1c1","magenta":"#b48ead","cyan":"#99c0d0","white":"#e5e9f0","brightBlack":"#4c566a","brightRed":"#bf616a","brightGreen":"#a3be8c","brightYellow":"#ebcb8b","brightBlue":"#81a1c1","brightMagenta":"#b48ead","brightCyan":"#8fbcbb","brightWhite":"#eceff4","background":"#1c1c1c","foreground":"#d8dee9","selection":"#4c566a","cursor":"#d8dee9"}

Hide

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

# Split off a clock pane on the right (herdr prefix is ctrl+a, per
# config.toml) -c centers the clock in the pane. tty-clock only supports
# the 8 basic ANSI colors via -C (no truecolor/hex), so -C 4 (blue) is
# resolved against the Set Theme palette above.
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

# Create the agent tab (prefix+c, auto-focused), then prefix+1 returns to
# the nvim tab -- this is what gives the final frame its 2-tab layout.
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

# Launch nvim with no file argument so it lands on the Alpha dashboard
# (configs/nvim/lua/plugin/appearance/alpha.lua) -- the real splash screen
# this setup shows, not vim's builtin :intro.
Type "nvim"
Enter

# Let nvim's own startup finish before the take begins.
Sleep 15s

# Spend fzf-lua's first invocation here, off camera.
#
# This is the one step that has never been reliable. Across every run of
# this workflow the *second* picker has populated correctly and the first
# has sometimes come up "0/0 (0)" -- empty, with the query typed into
# nothing and Enter opening no file, which takes the rest of the take with
# it. It is a race in the first invocation, not a slow machine: the
# picker window itself opens fine, it just never receives the file list.
#
# Priming (see the workflow) does not cover this. That fixes the machine
# -- mason's servers and the treesitter parsers are on disk before the
# take -- but fzf-lua is lazy-loaded, so every nvim launch still pays its
# first-invocation cost, and the run that produced the broken demo on
# main reported a perfectly healthy "parsers=22 mason=9 reason=settled".
#
# So open the picker once here and throw it away. Escape aborts without
# opening anything, leaving the Alpha dashboard exactly as it was, and
# the take below gets a second invocation -- the kind that has always
# worked.
Ctrl+P
Sleep 5s
Escape
Sleep 2s

Show
Sleep 1s

# Open the two files to work on, through the real file-finder keybinding
# (<C-p> -> fzf-lua files, per configs/nvim/lua/plugin/navigation/fzf.lua)
# rather than passing them on the command line.
#
# Typed in chunks with a small hesitation, which is what makes it read as
# typing rather than text appearing at once. The pause after is the glance
# at the match before accepting it.
Ctrl+P
Sleep 2s
Type@130ms "lsp"
Sleep 300ms
Type@130ms ".lua"
Sleep 700ms
Enter

# Straight on to the second file -- you already know both files you want
# open, so there's nothing to stop and read here.
#
# This was 8s for a while, purely to absorb lua-language-server's cold
# start: at 2s the second <C-p> raced lua_ls and opened empty. The
# priming session now pays that cost off camera (it holds a lua buffer
# open for two minutes, so lua_ls is installed and its workspace cache is
# warm), so what's left is just the hand moving between keystrokes.
Sleep 800ms

# Open plugin-manager.lua the same way, so it lands on top as the active
# buffer with both files in the tab bar. lua_ls has settled by now, so
# this picker gets the same 2s the first one did rather than extra margin.
Ctrl+P
Sleep 2s
Type@130ms "plugin"
Sleep 300ms
Type@130ms "-manager"
Sleep 700ms
Enter
Sleep 2s

# Find the line to work near. Short search string, like you would really
# type -- "plug = req" is already unique in this file (line 75).
Type@120ms "/plug = req"
Sleep 350ms
Enter
Sleep 700ms

# Add a line below it and start typing. plug_nvim_path, plugin_home and
# plug_nvim_url are real globals from lib/const.lua, so lua_ls offers them.
Type "o"
Sleep 400ms
Type@150ms "pl"
Sleep 900ms

# Walk the menu down to plugin_home with Tab (nvim-cmp's <Tab> mapping ->
# select_next_item, see configs/nvim/lua/plugin/autocomplete/cmp.lua).
# completeopt includes noselect, so nothing is highlighted until the first
# Tab, and the LSP orders these plug -> plug_nvim_path -> plugin_home:
# three presses. Paused between each so the selection moving is legible.
Tab
Sleep 550ms
Tab
Sleep 550ms
Tab
Sleep 1600ms

# Freeze this exact frame as a still, for a README that wants one
# alongside the demo. Off while the README carries only the gif.
# Screenshot ".github/screenshot.png"

# Hold briefly so the recording doesn't cut out on the final keystroke.
Sleep 2s
