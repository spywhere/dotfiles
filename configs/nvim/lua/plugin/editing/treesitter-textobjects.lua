local registry = require('lib.registry')

registry.install {
  'nvim-treesitter/nvim-treesitter-textobjects',
  delay = function ()
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
