local registry = require('lib.registry')
local bindings = require('lib.bindings')
local cache = require('lib.cache')

registry.install {
  'ibhagwan/fzf-lua',
  skip = registry.experiment('fuzzy').is_not('fzf'),
  defer = function ()
    local folder_filter = function (options)
      return function ()
        return vim.tbl_extend('keep', options or {}, {
          show_cwd_header=cache.has('filter_folder'),
          cwd=cache.get('filter_folder', vim.loop.cwd())
        })
      end
    end

    bindings.map.normal('<C-p>', function ()
      require('fzf-lua').files(folder_filter {})
    end)
    bindings.map.normal('<leader>/', require('fzf-lua').blines)
    bindings.map.normal('<leader>f', function ()
      require('fzf-lua').grep(folder_filter {
        search = ''
      })
    end)
    bindings.map.normal('<leader>F', function ()
      require('fzf-lua').live_grep(folder_filter {})
    end)
    bindings.map.normal('<leader><A-F>', function ()
      require('fzf-lua').live_grep(folder_filter {
        continue_last_search = true
      })
    end)
  end,
  config = function ()
    require('fzf-lua').setup {
      fzf_opts = {
        ['--layout']='default'
      },
      keymap = {
        builtin = {
          ['<C-_>'] = 'toggle-preview',
          ['<S-down>'] = 'preview-page-down',
          ['<S-up>'] = 'preview-page-up'
        },
        fzf = {
          ['ctrl-u'] = 'half-page-up',
          ['ctrl-d'] = 'half-page-down'
        }
      },
      grep = {
        exec_empty_query = true,
        no_header_i = true
      }
    }
  end
}
