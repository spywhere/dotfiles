local registry = require('lib.registry')

registry.install {
  'lukas-reineke/virt-column.nvim',
  config = function ()
    require('virt-column').setup()
  end
}
