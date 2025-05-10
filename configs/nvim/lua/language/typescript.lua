local lsp = require('lib.lsp')

lsp.setup('ts_ls')
  .experiment('vtsls').off()
  .need_executable('typescript-language-server')
lsp.setup('vtsls')
  .experiment('vtsls').on()
  .need_executable('vtsls')
