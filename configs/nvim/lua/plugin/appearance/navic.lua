local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'SmiteshP/nvim-navic',
  requires = 'neovim/nvim-lspconfig',
  lazy = true,
  config = function ()
    local navic = require('nvim-navic')

    navic.setup {
      highlight = true,
      separator = '  ',
      depth_limit = 5
    }

    lsp.on_attach(function (client, bufnr)
      if not client.server_capabilities.documentSymbolProvider then
        return
      end

      navic.attach(client, bufnr)
    end)
  end
}
