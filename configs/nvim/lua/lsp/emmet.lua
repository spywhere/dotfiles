local lsp = require('lib/lsp')

local capabilities = lsp.capabilities({
  snippetSupport = true
})

lsp.setup('ls_emmet')
  .need_executable('ls_emmet')
  .config({
    default_config = {
      cmd = { 'ls_emmet', '--stdio' },
      filetypes = { 'html', 'jsx', 'xml', 'css', 'scss', 'less' },
      root_dir = function ()
        return luv.cwd()
      end,
      settings = {}
    }
  })
  .options({
    capabilities = capabilities
  })
