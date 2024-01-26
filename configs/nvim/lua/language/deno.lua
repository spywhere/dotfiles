local lsp = require('lib.lsp')

lsp.setup('denols')
  .need_executable('deno')
  .root { 'deno.json', 'deno.jsonc' }
  .options {
    settings = {
      deno = {
        config = 'deno.json',
        importMap = 'import.json',
        enable = true,
        lint = true
      }
    }
  }
