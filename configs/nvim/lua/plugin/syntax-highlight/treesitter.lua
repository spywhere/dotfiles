local registry = require('lib.registry')

registry.install {
  'nvim-treesitter/nvim-treesitter',
  options = {
    ['do'] = ':TSUpdateSync'
  },
  config = function ()
    require('nvim-treesitter.configs').setup {
      sync_install = true,
      ensure_installed = 'all',
      ignore_install = {
        'julia', 'haskell', 'kotlin', 'ocamel', 'ocaml_interface',
        'ocamllex', 'verilog', 'zig'
      },
      highlight = {
        enable = true
      }
    }
  end
}
