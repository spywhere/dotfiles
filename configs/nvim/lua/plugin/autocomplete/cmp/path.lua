local registry = require('lib/registry')

registry.install {
  'hrsh7th/cmp-path',
  skip = registry.experiment('cmp').off
}
