local registry = require('lib/registry')

registry.install {
  'hrsh7th/cmp-cmdline',
  skip = registry.experiment('cmp').off
}
