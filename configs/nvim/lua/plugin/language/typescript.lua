local registry = require('lib.registry')

registry.install {
  'pmizio/typescript-tools.nvim',
  skip = registry.experiment('typescript-tools').off,
  requires = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  config = function()
    require('typescript-tools').setup {
      on_attach = function ()
        registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
        registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
      end
    }
  end,
}
