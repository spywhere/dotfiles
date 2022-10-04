local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'SmiteshP/nvim-navic',
  requires = 'neovim/nvim-lspconfig',
  lazy = true,
  config = function ()
    lsp.on_attach(function (client, bufnr)
      if not client.server_capabilities.documentSymbolProvider then
        return
      end

      require('nvim-navic').attach(client, bufnr)
    end)
  end
}
