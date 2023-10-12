local registry = require('lib.registry')

registry.install {
  'L3MON4D3/LuaSnip',
  config = function ()
    require("luasnip/loaders/from_vscode").lazy_load()
  end,
  options = {
    submodules = false
  }
}
