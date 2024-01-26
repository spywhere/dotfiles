local lsp = require('lib.lsp')

local capabilities = lsp.capabilities({
  snippetSupport = true
})

lsp.setup('emmet_ls')
  .need_executable('emmet_ls')
  .options {
    capabilities = capabilities
  }
