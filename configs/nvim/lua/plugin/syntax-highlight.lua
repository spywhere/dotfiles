local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.post(function ()
  if fn.has('termguicolors') == 1 then
    bindings.set('termguicolors')
  end
end)

registry.install {
  'norcalli/nvim-colorizer.lua',
  config = function ()
    vim.g.vim_markdown_conceal = 0
    vim.g.vim_markdown_conceal_code_blocks = 0
  end,
  defer = function ()
    require('colorizer').setup()
  end
}

registry.install('kien/rainbow_parentheses.vim')

if fn.has('nvim-0.5') == 1 then
  -- Experimental until nvim-0.5
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
