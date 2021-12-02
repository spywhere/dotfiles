local bindings = require('lib.bindings')
local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'neovim/nvim-lspconfig',
  defer = lsp.setup,
  config = function ()
    lsp.on_setup(function ()
      vim.diagnostic.config({
        virtual_text = false
      })
    end)

    lsp.on_attach(function (client)
      if not client.resolved_capabilities.document_highlight then
        return
      end

      bindings.highlight.link('LspReferenceRead', 'CursorColumn')
      bindings.highlight.link('LspReferenceText', 'CursorColumn')
      bindings.highlight.link('LspReferenceWrite', 'CursorColumn')
      registry.group(function ()
        registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
        registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
      end)
    end)
  end
}
