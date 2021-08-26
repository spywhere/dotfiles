local registry = require('lib/registry')

registry.install {
  'hrsh7th/cmp-nvim-lua',
  skip = registry.experiment('cmp').off,
  lazy = true
}
