local lsp = require('lib.lsp')

lsp.setup('lua_ls')
  .need_executable('lua-language-server')
  .options({
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT'
        },
        diagnostics = {
          globals = { 'vim' }
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true)
        },
        telemetry = {
          enable = false
        }
      }
    }
  })
