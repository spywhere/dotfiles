local registry = require('lib.registry')

registry.install {
  'spywhere/tmux.nvim',
  config = function ()
    local tmux = require('tmux')
    local cmds = require('tmux.commands')

    tmux.prefix('<C-a>')

    tmux.bind('|', cmds.split_window { 'v' })
    tmux.bind('-', cmds.split_window { 'h' })

    tmux.bind('h', cmds.select_pane { 'L' })
    tmux.bind('j', cmds.select_pane { 'D' })
    tmux.bind('k', cmds.select_pane { 'U' })
    tmux.bind('l', cmds.select_pane { 'R' })

    tmux.bind('r', cmds.rotate_window {})

    tmux.bind('<S-Left>', cmds.previous_window {}, { T = 'root' })
    tmux.bind('<S-Right>', cmds.next_window {}, { T = 'root' })

    vim.o.shell = string.format('%s/.dots/binaries/shell', vim.env.HOME)
    tmux.start()
  end
}
