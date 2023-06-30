local registry = require('lib.registry')
local bindings = require('lib.bindings')
local cache = require('lib.cache')

registry.install {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.2',
  requires = {
    {
      'nvim-lua/plenary.nvim'
    },
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    }
  },
  defer = function ()
    local telescope = function (action, options)
      return function ()
        if type(options) == 'function' then
          options = options()
        end
        require('telescope.builtin')[action](options)
      end
    end

    bindings.map.normal('<C-p>', telescope('find_files', {
      prompt_prefix='Find> ',
      hidden = true
    }))
    bindings.map.normal('<leader>/', telescope('current_buffer_fuzzy_find', {
      prompt_prefix='BLines> '
    }))
    -- fuzzy search buffer content (.buffers is fuzzy search buffer selection)
    bindings.map.normal('<leader>f', function ()
      require('telescope.builtin').live_grep {
        prompt_prefix='Rg> ',
        search_dirs=vim.tbl_keys(cache.get('filter_folder', {}))
      }
    end)
    -- TODO: ripgrep the whole project with rg itself
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
        dynamic_preview_title = true,
        winblend = 15,
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

    require('telescope').load_extension('fzf')
  end
}
