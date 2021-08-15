local lsp = require('lib/lsp')

local capabilities = lsp.capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

lsp.setup('emmet_ls')
  .need_executable('emmet-ls')
  .config({
    default_config = {
      cmd = { 'emmet-ls', '--stdio' },
      filetypes = { 'html', 'css' },
      root_dir = function ()
        return luv.cwd()
      end,
      settings = {}
    }
  })
  .options({
    capabilities = capabilities
  })
