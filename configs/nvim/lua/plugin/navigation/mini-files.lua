local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'echasnovski/mini.files',
  skip = registry.experiment('explorer').not_be('mini.files'),
  requires = {
    'echasnovski/mini.icons',
  },
  config = function ()
    require('mini.files').setup {
      mappings = {
        go_in = '<tab>',
        go_in_plus = '<cr>',
        go_out = '-',
      },
      windows = {
        preview = true
      }
    }

    registry.auto('User', function (args)
      local keymap = function (lhs, fn)
        vim.keymap.set('n', lhs, require('mini.files')[fn], {
          buffer = args.data.buf_id,
        })
      end

      keymap('<c-l>', 'go_in')
      keymap('<c-h>', 'go_out')
      keymap('<c-i>', 'go_in')
      keymap('<c-o>', 'go_out')
      keymap('<leader>w', 'synchronize')
    end, 'MiniFilesBufferCreate')

    bindings.map.normal('<leader>e', function ()
      local files = require('mini.files')
      if not files.close() then
        files.open(api.nvim_buf_get_name(0))
      end
    end)
  end
}
