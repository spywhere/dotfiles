local registry = require('lib.registry')

registry.install {
  'j-hui/fidget.nvim',
  tag = "v1.2.0",
  lazy = true,
  config = function ()
    require('fidget').setup {}
  end
}
