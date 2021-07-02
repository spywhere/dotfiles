local lsp = require('lib/lsp')

lsp.setup('tsserver')
  .need_executable('typescript-language-server')
