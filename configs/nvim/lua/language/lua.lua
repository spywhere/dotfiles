local lsp = require('lib.lsp')

lsp.setup('lua_ls')
  .need_executable('lua-language-server')
