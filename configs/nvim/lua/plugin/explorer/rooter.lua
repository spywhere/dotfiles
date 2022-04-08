local registry = require('lib.registry')

registry.install {
  'ygm2/rooter.nvim',
  skip = registry.experiment('rooter').off,
}
