local registry = require('lib.registry')

registry.install {
  'stevearc/dressing.nvim',
  config = function ()
    require('dressing').setup {}
  end
}
