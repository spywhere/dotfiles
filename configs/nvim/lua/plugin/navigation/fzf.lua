local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'ibhagwan/fzf-lua',
  skip = registry.experiment('telescope').on,
  requires = {
    'nvim-tree/nvim-web-devicons'
  },
  config = function ()
    local actions = require('fzf-lua.actions')
    require('fzf-lua').setup {
      winopts = {
        height = 0.9,
        width = 0.9
      },
      fzf_opts = {
        ['--layout'] = 'default'
      },
      files = {
        no_header = true,
        git_icons = false
      },
      grep = {
        no_header = true,
        rg_glob = true,
        rg_opts = "--column --line-number --no-heading --hidden --color=always --smart-case --max-columns=4096 -e",
      },
      keymap = {
        builtin = {
          ['<C-_>'] = 'toggle-preview',
          ['<C-u>'] = 'preview-page-up',
          ['<C-d>'] = 'preview-page-down',
          ['<S-up>'] = 'preview-up',
          ['<S-down>'] = 'preview-down',
        },
        fzf = {
          ['ctrl-b'] = 'half-page-up',
          ['ctrl-f'] = 'half-page-down',
          ['ctrl-u'] = 'preview-half-page-up',
          ['ctrl-d'] = 'preview-half-page-down',
          ['ctrl-a'] = 'beginning-of-line',
          ['ctrl-e'] = 'end-of-line',
          ['alt-q'] = 'select-all+accept',
          ['ctrl-/'] = 'toggle-preview',
        }
      },
      actions = {
        files = {
          ['default'] = actions.file_edit_or_qf,
          ['ctrl-s'] = actions.file_split,
          ['ctrl-v'] = actions.file_vsplit,
          ['ctrl-t'] = actions.file_tabedit,
          ['ctrl-q'] = actions.file_sel_to_qf
        }
      }
    }

    local fuzzy = function (action, options)
      return function ()
        if type(options) == 'function' then
          options = options()
        end
        require('fzf-lua')[action](options)
      end
    end

    bindings.map.normal('<C-p>', fuzzy('files'))
    bindings.map.normal('<leader>/', fuzzy('blines', {
      prompt_prefix='BLines> '
    }))
    -- fuzzy search buffer content (.buffers is fuzzy search buffer selection)
    bindings.map.normal('<leader>f', fuzzy('live_grep'))
  end
}
