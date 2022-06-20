local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'nvim-telescope/telescope.nvim',
  skip = registry.experiment('fzf').on,
  requires = {
    {
      'nvim-lua/plenary.nvim'
    }
  },
  defer = function ()
    bindings.map.normal('<C-p>', {
      import = 'telescope.builtin',
      'find_files({ prompt_prefix="Find> ", hidden = true })'
    })
    bindings.map.normal('<leader>/', {
      import = 'telescope.builtin',
      'current_buffer_fuzzy_find({ prompt_prefix="BLines> " })'
    })
    -- fuzzy search buffer content (.buffers is fuzzy search buffer selection)
    bindings.map.normal('<leader>f', {
      import = 'telescope.builtin',
      'live_grep({ prompt_prefix="Rg> " })'
    })
    -- ripgrep the whole project with rg itself
  end,
  config = function ()
    local actions = require('telescope.actions')
    local layout_actions = require('telescope.actions.layout')

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
            ['<S-Up>'] = actions.preview_scrolling_up,
            ['<S-Down>'] = actions.preview_scrolling_down,
            ['<C-u>'] = actions.results_scrolling_up,
            ['<C-d>'] = actions.results_scrolling_down,
            ['<C-q>'] = actions.smart_send_to_qflist + actions.open_qflist,
            ['<C-_>'] = layout_actions.toggle_preview
          }
        }
      }
    }
  end
}
