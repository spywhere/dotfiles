local lsp = require('lib.lsp')

lsp.setup('denols')
  .need_executable('deno')
  .options({
    settings = {
      deno = {
        config = 'deno.json',
        importMap = 'import.json',
        enable = true,
        lint = true
      }
    }
  })
