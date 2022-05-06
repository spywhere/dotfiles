local registry = require('lib.registry')

registry.install {
  'nvim-treesitter/nvim-treesitter',
  options = {
    ['do'] = function (info)
      if info.status == 'installed' then
        return
      end

      if fn.has('linux') == 1 then
        vim.cmd('TSUpdateSync')
      else
        vim.cmd('TSUpdate')
      end
    end
  },
  config = function ()
    require('nvim-treesitter.configs').setup {
      sync_install = fn.has('linux') == 1,
      ensure_installed = 'all',
      ignore_install = {
        'julia', 'haskell', 'kotlin', 'ocamel', 'ocaml_interface',
        'ocamllex', 'phpdoc', 'verilog', 'zig'
      },
      highlight = {
        enable = true
      }
    }
  end
}
