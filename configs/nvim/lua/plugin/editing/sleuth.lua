local registry = require('lib.registry')

registry.install {
  'tpope/vim-sleuth',
  skip = registry.experiment('guess-indent').on,
  lazy = true
}
