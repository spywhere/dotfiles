local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'folke/trouble.nvim',
  config = function ()
    bindings.map.normal('<leader>WD', '<cmd>TroubleToggle lsp_workspace_diagnostics<cr>')
    bindings.map.normal('<leader>DD', '<cmd>TroubleToggle lsp_document_diagnostics<cr>')
    bindings.map.normal('gR', '<cmd>TroubleToggle lsp_references<cr>')
  end,
  delay = function ()
    require("trouble").setup({})
  end
}
