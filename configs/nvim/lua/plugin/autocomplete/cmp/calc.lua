local registry = require('lib/registry')

registry.install {
  'hrsh7th/cmp-calc',
  skip = registry.experiment('cmp').off,
  lazy = true
}
