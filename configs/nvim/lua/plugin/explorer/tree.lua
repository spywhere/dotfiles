local bindings = require('lib.bindings')
local registry = require('lib.registry')
local cache = require('lib.cache')

registry.install {
  'kyazdani42/nvim-tree.lua',
  config = function ()
    vim.g.nvim_tree_icons = {
      default = ' '
    }
  end,
  defer = function ()
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
  delay = function ()
    local update_filter_folder = function (node)
      if node.name == '..' then
        print('Filter cleared')
        cache.del('filter_folder')
        return
      elseif not node.fs_stat or node.fs_stat.type ~= 'directory' then
        return
      end

      cache.set('filter_folder', node.absolute_path)
      print('Filter:', node.absolute_path)
    end

    require('nvim-tree').setup {
      view = {
        mappings = {
          list = {
            {
              key = 'f',
              action = 'update_filter_folder',
              action_cb = update_filter_folder
            }
          }
        }
      },
      update_focused_file = {
        enable = true
      },
      actions = {
        change_dir = {
          global = true
        }
      }
    }
  end
}
