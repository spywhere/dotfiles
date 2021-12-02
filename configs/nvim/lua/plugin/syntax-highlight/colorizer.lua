local registry = require('lib.registry')

registry.install {
  'norcalli/nvim-colorizer.lua',
  config = function ()
    vim.g.vim_markdown_conceal = 0
    vim.g.vim_markdown_conceal_code_blocks = 0
  end,
  defer = function ()
    require('colorizer').setup()
  end
}
