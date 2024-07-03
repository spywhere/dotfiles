local registry = require('lib.registry')

registry.install {
  'lewis6991/gitsigns.nvim',
  lazy = true,
  config = function ()
    require('gitsigns').setup {
      signs = {
        add = { text = '+' },
        change = { text = '!' }
      }
    }
  end
}
