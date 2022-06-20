local registry = require('lib.registry')

registry.install {
  'danymat/neogen',
  lazy = true,
  config = function ()
    require('neogen').setup {}
  end
}
