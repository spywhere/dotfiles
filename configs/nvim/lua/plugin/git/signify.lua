local registry = require('lib.registry')

registry.install {
  'lewis6991/gitsigns.nvim',
  lazy = true,
  config = function ()
    require('gitsigns').setup {
      signs = {
        add = { hl = 'GitSignsAdd', text = '+', numhl='GitSignsAddNr', linehl='GitSignsAddLn' },
        change = { hl = 'GitSignsChange', text = '!', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' }
      }
    }
  end
}
