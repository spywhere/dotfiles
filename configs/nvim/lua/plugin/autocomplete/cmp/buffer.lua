local registry = require('lib/registry')

registry.install {
  'hrsh7th/cmp-buffer',
  skip = registry.experiment('cmp').off
}
