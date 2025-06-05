local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'stevearc/oil.nvim',
  skip = registry.experiment('explorer').not_be('oil'),
  requires = {
    'echasnovski/mini.icons',
    'nvim-tree/nvim-web-devicons'
  },
  config = function ()
    require('oil').setup {
      buf_options = {
        buflisted = true,
        bufhidden = 'delete'
      },
      keymaps = {
        ['<C-l>'] = false,
        ['<C-h>'] = false,
        ['<C-p>'] = false,
        ['<C-s>'] = { 'actions.select', opts = { horizontal = true } },
        ['<C-v>'] = { 'actions.select', opts = { vertical = true } },
        ['<C-_>'] = { 'actions.preview' },
        ['<C-]>'] = { 'actions.select' },
        ['<C-i>'] = { 'actions.select' },
        ['<C-o>'] = { 'actions.parent', mode = 'n' },
      }
    }

    bindings.map.normal('<leader>e', function ()
      local oil = require('oil')
      if vim.bo.filetype == 'oil' then
        oil.close()
        return
      end
      oil.open()
    end)
  end
}
