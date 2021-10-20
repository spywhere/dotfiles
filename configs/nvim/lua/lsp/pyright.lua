local lsp = require('lib/lsp')

lsp.setup('pyright')
  .need_executable('pyright-langserver')
