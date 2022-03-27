local registry = require('lib.registry')

registry.install {
  'danymat/neogen',
  skip = registry.experiment('doge').on,
  lazy = true,
  config = function ()
    require('neogen').setup {}
  end
}
