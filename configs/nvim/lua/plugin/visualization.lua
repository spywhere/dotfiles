local registry = require('lib/registry')

registry.install('Yggdroot/indentLine', { lazy = 'indentLine' })
registry.post(function ()
  vim.g.indentLine_char = '|'
  vim.g.indentLine_leadingSpaceChar = '·'
  vim.g.indentLine_fileTypeExclude = { 'text', 'startify' }
end)

registry.install(
  'jeffkreeftmeijer/vim-numbertoggle',
  { lazy = 'vim-numbertoggle' }
)
registry.install(
  'AndrewRadev/linediff.vim',
  { lazy = 'linediff.vim' }
)
