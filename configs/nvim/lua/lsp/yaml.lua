local lsp = require('lib/lsp')

lsp.setup('yamlls')
  .need_executable('yaml-language-server')
