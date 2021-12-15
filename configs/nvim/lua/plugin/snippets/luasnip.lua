local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'L3MON4D3/LuaSnip',
  config = function ()
    require("luasnip/loaders/from_vscode").lazy_load()
  end
}
