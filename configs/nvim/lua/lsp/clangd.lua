local lsp = require('lib.lsp')

lsp.setup('clangd')
  .need_executable('clangd')
