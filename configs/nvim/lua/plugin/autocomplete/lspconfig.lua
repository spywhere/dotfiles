local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'williamboman/mason-lspconfig.nvim',
  requires = {
    'williamboman/mason.nvim',
    'neovim/nvim-lspconfig'
  },
  delay = lsp.setup(function (handler)
    require('mason-lspconfig').setup {
      ensure_installed = {
        'bashls', 'emmet_ls', 'eslint', 'graphql', 'lua_ls', 'pyright', 'tsserver', 'vimls', 'yamlls'
      },
      handlers = { handler }
    }
  end, {
    skip_check = true
  }),
  config = function ()
    require('mason').setup()
    lsp.on_setup(function ()
      vim.diagnostic.config({
        virtual_text = false
      })
    end)

    lsp.on_attach(function (client)
      if fn.has('nvim-0.8') == 1 and not client.server_capabilities.documentHighlightProvider then
        return
      elseif fn.has('nvim-0.8') == 0 and not client.resolved_capabilities.document_highlight then
        return
      end

      registry.group(function ()
        registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
        registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
      end)
    end)
  end
}
