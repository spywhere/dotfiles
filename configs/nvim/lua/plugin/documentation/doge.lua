local registry = require('lib.registry')

registry.install {
  'kkoomen/vim-doge',
  skip = registry.experiment('doge').off,
  lazy = true,
  options = {
    ['do'] = ':call doge#install()'
  },
  setup = function ()
    vim.g.doge_enable_mappings = 0
  end
}
