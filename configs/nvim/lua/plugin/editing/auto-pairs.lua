local registry = require('lib.registry')

registry.install {
  'windwp/nvim-autopairs',
  delay = function ()
    require('nvim-autopairs').setup { map_cr = true }
  end
}
