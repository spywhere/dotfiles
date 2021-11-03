local lsp = require('lib/lsp')

lsp.setup('sumneko_lua')
  .need_executable('lua-language-server')
  .command({ 'lua-language-server' })
  .options({
    settings = {
      Lua = {
        diagnostics = {
          globals = {
            'vim'
          }
        }
      }
    }
  })
