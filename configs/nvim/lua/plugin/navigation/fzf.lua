local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'ibhagwan/fzf-lua',
  skip = registry.experiment('telescope').on,
  requires = {
    'nvim-tree/nvim-web-devicons'
  },
  config = function ()
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
        rg_glob = true
      },
      keymap = {
        builtin = {
          ['<C-_>'] = 'toggle-preview',
        },
        fzf = {
          ['ctrl-u'] = 'half-page-up',
          ['ctrl-d'] = 'half-page-down',
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
