local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install {
  'tpope/vim-sleuth',
  lazy = true
}
registry.install {
  'preservim/nerdcommenter',
  lazy = true,
  config = function ()
    vim.g.NERDSpaceDelims = 1
  end
}

registry.install('tpope/vim-repeat')
registry.install('tpope/vim-surround')
registry.install {
  'tpope/vim-unimpaired',
  lazy = true
}
-- would be nice if it works nicely with completion plugins
-- registry.install('tpope/vim-endwise')
registry.install('jiangmiao/auto-pairs')
registry.install('itchyny/vim-parenmatch')
registry.install('christoomey/vim-sort-motion')

registry.install {
  'nvim-treesitter/nvim-treesitter-textobjects',
  defer = function ()
    require('nvim-treesitter.configs').setup({
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner"
          }
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = "@parameter.inner"
          },
          swap_previous = {
            ["<leader>A"] = "@parameter.inner"
          }
        }
      }
    })
  end
}

registry.install('AndrewRadev/switch.vim')
registry.install {
  'tpope/vim-speeddating',
  config = function ()
    -- disabled as we will map switch.vim and speeddating ourselves
    vim.g.speeddating_no_mappings = 1
  end,
  defer = function ()
    -- avoid issues because of remap belows
    bindings.map.normal('<Plug>SpeedDatingFallbackUp', '<c-a>')
    bindings.map.normal('<Plug>SpeedDatingFallbackDown', '<c-x>')

    -- manually invoke speedating in case switch didn't work
    bindings.map.normal('<c-a>', '<cmd>if !switch#Switch() <bar>call speeddating#increment(v:count1) <bar> endif<cr>')
    bindings.map.normal('<c-x>', '<cmd>if !switch#Switch({\'reverse\': 1}) <bar>call speeddating#increment(-v:count1) <bar> endif<cr>')
  end
}

registry.install('lambdalisue/suda.vim')
