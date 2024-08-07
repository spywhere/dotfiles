local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'ray-x/lsp_signature.nvim',
  config = function ()
    lsp.on_attach(function (_, bufnr)
      require('lsp_signature').on_attach({
        hint_enable = false,
      }, bufnr)
    end)
  end
}
