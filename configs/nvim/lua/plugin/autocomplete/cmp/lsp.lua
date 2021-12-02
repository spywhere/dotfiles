local registry = require('lib.registry')

registry.install {
  'hrsh7th/cmp-nvim-lsp',
  skip = registry.experiment('cmp').off
}
