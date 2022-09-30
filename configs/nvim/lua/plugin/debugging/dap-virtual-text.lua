local registry = require('lib.registry')

registry.install {
  'theHamsta/nvim-dap-virtual-text',
  requires = {
    'mfussenegger/nvim-dap',
    'nvim-treesitter/nvim-treesitter'
  }
}
