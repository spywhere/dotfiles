local registry = require('lib.registry')

registry.install {
  'williamboman/mason.nvim',
  config = function ()
    require('mason').setup()
  end
}
