local registry = require('lib.registry')

registry.install {
  'kylechui/nvim-surround',
  config = function ()
    require('nvim-surround').setup {}
  end
}
