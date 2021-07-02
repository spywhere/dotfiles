local lsp = require('lib/lsp')

lsp.setup('bashls')
  .need_executable('bash-language-server')
