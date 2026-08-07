# Priming pass. Runs before dotfiles.tape and produces nothing worth
# keeping -- its whole job is to let the setup do its first-run work once,
# so the recording that follows shows the editor as it behaves every day
# after that, rather than the one-time cost of a cold machine.
#
# Why this exists as a tape rather than a headless nvim: mason will not
# install in headless mode. A bootstrap step that opened a lua buffer and
# waited 90s reported "mason=0 opened=lua" with an empty package
# directory, while the same config in a real terminal installs all nine
# servers happily. So the priming session needs a PTY, and vhs is already
# the thing that gives us one.
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

# `; echo PRIMED` gives the Wait below something to look for: nvim quits
# by itself once the wait script decides everything has settled, and the
# marker only reaches the screen after that has happened.
Type "nvim; echo PRIMED"
Enter

# Let startup finish -- plug.nvim defers its config, and the FileType
# autocmd that brings the LSP path (and so mason) to life is registered in
# that deferred pass. Opening the file before it exists is exactly why the
# headless attempts never triggered anything.
Sleep 20s

Type ":e configs/nvim/lua/lib/lsp.lua"
Enter
Sleep 5s

# Hand over to the wait script, which polls treesitter's and mason's
# installed counts and quits nvim once both have settled. Written by the
# workflow to a fixed path, since a tape cannot read the environment.
Type ":luafile /tmp/nvim-prime-wait.lua"
Enter

# Block until the shell prints the marker, i.e. until nvim has exited.
# Bounded so a stuck install fails the step instead of hanging the job.
Wait+Screen@12m /PRIMED/

Show
Sleep 2s
