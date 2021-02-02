local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install('szw/vim-maximizer', { lazy = 'vim-maximizer' })
registry.defer(function ()
  bindings.map.normal('<leader>z', '<cmd>MaximizerToggle!<cr>')
end)
