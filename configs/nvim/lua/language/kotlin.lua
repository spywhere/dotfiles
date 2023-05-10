local lsp = require('lib.lsp')

lsp.setup('kotlin_language_server')
  .need_executable('kotlin-language-server')
