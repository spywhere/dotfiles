local registry = require('lib/registry')

registry.install {
  'https://github.com/windwp/nvim-autopairs',
  defer = function ()
    require('nvim-autopairs').setup { map_cr = true }
  end
}
