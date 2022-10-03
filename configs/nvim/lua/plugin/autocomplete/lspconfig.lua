local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'neovim/nvim-lspconfig',
  delay = lsp.setup,
  config = function ()
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
