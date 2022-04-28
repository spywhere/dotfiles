local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.install {
  'szw/vim-maximizer',
  lazy = true,
  delay = function ()
    bindings.map.normal('<leader>z', '<cmd>MaximizerToggle!<cr>')
  end
}
