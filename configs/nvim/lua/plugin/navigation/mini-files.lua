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
        go_in = '<cr>',
        go_out = '-',
      },
      windows = {
        preview = true
      }
    }

    bindings.map.normal('<leader>e', function ()
      local files = require('mini.files')
      if not files.close() then
        files.open(api.nvim_buf_get_name(0))
      end
    end)
  end
}
