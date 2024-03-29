local lsp = require('lib.lsp')

lsp.setup('rust_analyzer')
  .need_executable('rust-analyzer')
  .options {
    settings = {
      ['rust-analyzer'] = {
        check = {
          command = 'clippy'
        }
      }
    }
  }
