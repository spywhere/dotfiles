local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.install {
  'kyazdani42/nvim-tree.lua',
  config = function ()
    vim.g.nvim_tree_icons = {
      default = ' '
    }
  end,
  defer_first = function ()
    local show_cursorline = function ()
      if vim.bo.filetype == 'NvimTree' then
        vim.wo.cursorline = true
        return
      end

      vim.wo.cursorline = false
    end
    -- show cursorline when browsing in the tree explorer
    registry.auto({ 'BufEnter', 'FileType' }, show_cursorline)

    bindings.map.all('<leader>e', '<cmd>NvimTreeToggle<cr>')
    bindings.map.all('<leader>E', '<cmd>NvimTreeFindFile<cr>')
  end,
  defer = function ()
    require('nvim-tree').setup {
      update_focused_file = {
        enable = true
      },
      filters = {
        dotfiles = true
      },
      actions = {
        change_dir = {
          global = true
        }
      }
    }
  end
}
