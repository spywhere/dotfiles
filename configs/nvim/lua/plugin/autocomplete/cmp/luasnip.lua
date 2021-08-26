local registry = require('lib/registry')

registry.install {
  'saadparwaiz1/cmp_luasnip',
  skip = registry.experiment('cmp').off
}
