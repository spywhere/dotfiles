local registry = require('lib.registry')
local lsp = require('lib.lsp')

registry.install {
  'onsails/lspkind-nvim',
  config = function ()
    -- symbol icon for completion items
    lsp.on_setup(require('lspkind').init)
  end
}
