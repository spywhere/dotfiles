local lsp = require('lib.lsp')

lsp.setup('ts_ls')
  .experiment('vtsls').off()
  .need_executable('typescript-language-server')
  .root { 'package.json', 'tsconfig.json', 'jsconfig.json' }
lsp.setup('vtsls')
  .experiment('vtsls').on()
  .need_executable('vtsls')
  .root { 'package.json', 'tsconfig.json', 'jsconfig.json' }
