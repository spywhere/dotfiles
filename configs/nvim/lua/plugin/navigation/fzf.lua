local registry = require('lib.registry')
local bindings = require('lib.bindings')
local gpt = require('gpt')

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
      },
      grep = {
        no_header = true,
        hidden = true
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
    bindings.map.normal('<leader>f', fuzzy('live_grep', {
      exec_empty_query = true
    }))

    if registry.experiment('explorer').is_not('tree') then
      local cmd = (function()
        if vim.fn.executable('fd') then
          return 'fd --type d --hidden --exclude .git --exclude node_modules'
        else
          return 'find -type d -not -path "*/\\.git/*" -not -path "*/node_modules/*"'
        end
      end)()

      bindings.map.normal('<leader>c', function ()
        local fzf = require('fzf-lua')
        fzf.fzf_exec(cmd, {
          prompt = registry.experiment('explorer').is('oil') and 'Oil> ' or 'Mini.Files> ',
          actions = {
            ['default'] = function(selection)
              if not selection then
                return
              end

              if registry.experiment('explorer').is('oil') then
                require('oil').open(selection[1])
              else
                require('mini.files').open(selection[1])
              end
            end
          }
        })
      end)
    end

    if registry.experiment('gpt').on() then
      bindings.map.normal('<leader>g', gpt.fzf)
      bindings.map.normal('<leader>G', gpt.prompt_create)
    end
  end
}
