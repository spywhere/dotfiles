local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'nvim-telescope/telescope.nvim',
  defer_first = function ()
    bindings.map.normal('<C-p>', '<cmd>lua require("telescope.builtin").find_files({ prompt_prefix="Find> ", hidden = true })<cr>')
    bindings.map.normal('<leader>/', '<cmd>lua require("telescope.builtin").current_buffer_fuzzy_find({ prompt_prefix="BLines> " })<cr>')
    -- fuzzy search buffer content (.buffers is fuzzy search buffer selection)
    bindings.map.normal('<leader>f', '<cmd>lua require("telescope.builtin").live_grep({ prompt_prefix="Rg> " })<cr>')
    -- ripgrep the whole project with rg itself
  end,
  config = function ()
    local actions = require('telescope.actions')

    require('telescope').setup {
      defaults = {
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          -- additional options
          '--hidden'
        },
        scroll_strategy = 'limit',
        layout_config = {
          horizontal = { width = 0.9, height = 0.9 }
        },
        mappings = {
          i = {
            ['<esc>'] = actions.close,
            ['<S-Up>'] = actions.move_to_top,
            ['<S-Down>'] = actions.move_to_bottom
          }
        }
      }
    }
  end
}
