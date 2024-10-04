local lsp = require('lib.lsp')

lsp.setup('ts_ls')
  .need_executable('typescript-language-server')
  .root { 'package.json', 'tsconfig.json', 'jsconfig.json' }
