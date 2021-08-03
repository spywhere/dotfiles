local registry = require('lib/registry')
local bindings = require('lib/bindings')

registry.install {
  'tpope/vim-fugitive',
  skip = true,
  -- experimental
  -- 'TimUntersberger/neogit',
  lazy = true,
  config = function ()
    bindings.map.normal('gst', '<cmd>Git<cr>')
    -- bindings.map.normal('gst', '<cmd>Neogit<cr>')
    bindings.map.normal('gdd', '<cmd>Git diff<cr>')
    -- bindings.map.normal('gdd', '<cmd>Neogit diff<cr>')
    bindings.map.normal('gds', '<cmd>Git diff --staged<cr>')
  end
}
