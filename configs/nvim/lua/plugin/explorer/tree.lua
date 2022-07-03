local bindings = require('lib.bindings')
local registry = require('lib.registry')
local cache = require('lib.cache')

registry.install {
  'kyazdani42/nvim-tree.lua',
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
    bindings.map.all('<leader>E', '<cmd>NvimTreeFocus<cr>')
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

      local folders = cache.get('filter_folder', {})
      local item = node.absolute_path
      if folders[item] then
        folders[item] = nil
      else
        folders[item] = true
      end
      cache.set('filter_folder', folders)
      print('Filters:', table.concat(vim.tbl_keys(folders), ', '))
    end

    local show_filter_folder = function ()
      local folders = cache.get('filter_folder', {})
      print('Filters:', table.concat(vim.tbl_keys(folders), ', '))
    end

    require('nvim-tree').setup {
      sync_root_with_cwd = true,
      view = {
        mappings = {
          list = {
            {
              key = 'f',
              action = 'update_filter_folder',
              action_cb = update_filter_folder
            },
            {
              key = 'F',
              action = 'show_filter_folder',
              action_cb = show_filter_folder
            },
            {
              key = '/',
              action = 'live_filter',
            },
            {
              key = '<C-c>',
              action = 'clear_live_filter',
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
