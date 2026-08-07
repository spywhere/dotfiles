# Priming pass. Runs before dotfiles.tape and produces nothing worth
# keeping -- its whole job is to let the setup do its entire first-run work
# once, so the recording that follows shows the editor as it behaves every
# day after that, rather than the one-time cost of a cold machine.
#
# This is the *only* cold-start pass: plugin download included. There used
# to be a separate `nvim --headless "+Lazy! sync" +qa` step in front of it,
# which meant the machine paid two cold starts and the tape below was tuned
# for a half-warm one. One session does both now.
#
# Why this exists as a tape rather than a headless nvim: mason will not
# install in headless mode. A bootstrap step that opened a lua buffer and
# waited 90s reported "mason=0 opened=lua" with an empty package directory,
# while the same config in a real terminal installs all nine servers
# happily. So the priming session needs a PTY, and vhs is already the thing
# that gives us one.
#
# Nothing is typed at nvim. Everything the session does is driven from
# /tmp/nvim-prime.lua (written by the workflow -- a tape cannot read the
# environment), which waits for lazy, opens the lua buffer itself, waits
# for treesitter and mason, then quits. That matters: the earlier version
# typed `:e ...` and `:luafile ...` on fixed sleeps, which was only safe
# because plugins were already on disk. With the download happening here,
# those keystrokes would land mid-install, in whatever window lazy happens
# to have focused. Timing the download is guesswork; polling it is not.
#
# --cmd runs before init.lua, so the options are in place for the messages
# the first run emits. A hit-enter prompt would block the script's timer
# callback (nothing is scheduled while nvim waits on input) and there are
# no keystrokes coming to dismiss it, so a roomy cmdheight and shortmess+=F
# are what keep the session from parking on one. Same class of problem as
# the wakatime and tree-sitter-CLI prompts the workflow already heads off.
#
# Deliberately no herdr here: this only needs nvim, and keeping the
# multiplexer out avoids the recording tape later reattaching to a
# leftover server (it is persistent, and that has bitten this setup
# before).
#
# Nothing is on camera -- everything is inside Hide, with a couple of
# frames shown at the very end because vhs exits with "no frames /
# recording failed" otherwise. The gif is a throwaway and is gitignored.
# Note the trailing Sleep has to be long enough to actually produce a
# frame at the framerate set below: 200ms at 2fps rounds down to nothing
# and fails exactly as if Show had been missing.

Output "prime.gif"

Set Shell "zsh"
Set Width 1200
Set Height 800
Set Framerate 2

Hide

# Let zsh/zinit finish its own first-run bootstrap first
Sleep 10s

# The trailing echo gives the Wait below something to look for: nvim quits
# by itself once the script decides everything has settled, and the marker
# only reaches the screen after that has happened.
#
# The quotes in PRIM'ED' are load-bearing, not a typo. Wait+Screen matches
# against whatever is on screen *now*, and the command line vhs just typed
# is on screen -- so a marker spelled out literally here matches itself the
# instant the Wait starts, before nvim has even taken over the screen. That
# is not hypothetical: it is how the first run of this tape "primed" in
# four seconds and left nvim to be killed as an orphan at job cleanup. zsh
# strips the quotes, so the echo still prints PRIMED; the typed line does
# not contain it.
#
# The previous version of this tape was accidentally immune -- it typed two
# more commands after this one, so by the time it reached the Wait, nvim
# owned the alternate screen and the shell line was no longer visible.
Type "nvim --cmd 'set cmdheight=5 shortmess+=F' -c 'luafile /tmp/nvim-prime.lua'; echo PRIM'ED'"
Enter

# Block until the shell prints the marker, i.e. until nvim has exited.
# Bounded so a stuck install fails the step instead of hanging the job --
# generously, since this now covers the plugin download too, and the
# script's own budgets (see the workflow) are what should be reporting a
# stall first. This is the outer backstop, not the real limit.
Wait+Screen@25m /PRIMED/

Show
Sleep 2s
