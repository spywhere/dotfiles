local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'christoomey/vim-tmux-navigator',
  lazy = true,
  setup = function ()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function ()
    bindings.map.normal('<C-h>', ':<C-U>TmuxNavigateLeft<cr>')
    bindings.map.normal('<C-j>', ':<C-U>TmuxNavigateDown<cr>')
    bindings.map.normal('<C-k>', ':<C-U>TmuxNavigateUp<cr>')
    bindings.map.normal('<C-l>', ':<C-U>TmuxNavigateRight<cr>')
  end
}
