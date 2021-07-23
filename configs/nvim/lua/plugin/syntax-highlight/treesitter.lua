local registry = require('lib/registry')

if fn.has('nvim-0.5') == 1 then
  registry.install {
    'nvim-treesitter/nvim-treesitter',
    options = {
      ['do'] = ':TSUpdate'
    },
    config = function ()
      require('nvim-treesitter.configs').setup {
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
end
