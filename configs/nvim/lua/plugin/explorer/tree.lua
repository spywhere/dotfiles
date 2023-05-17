local bindings = require('lib.bindings')
local registry = require('lib.registry')
local cache = require('lib.cache')

local update_filter_folder = function ()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
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

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'f', update_filter_folder, opts('update_filter_folder'))
  vim.keymap.set('n', 'F', show_filter_folder, opts('show_filter_folder'))
  vim.keymap.set('n', '?', api.live_filter.start, opts('Filter'))
  vim.keymap.set('n', '<C-c>', api.live_filter.clear, opts('Clean Filter'))
end

registry.install {
  'nvim-tree/nvim-tree.lua',
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

    bindings.map.all('<leader>E', '<cmd>NvimTreeFocus<cr>')

    bindings.map.all('<leader>e', function ()
      local tree = require('nvim-tree.api').tree
      local view = require('nvim-tree.view')

      if
        view.is_visible() and
        api.nvim_get_current_win() ~= view.get_winnr()
      then
        tree.focus()
      else
        tree.toggle()
      end
    end)
  end,
  delay = function ()
    require('nvim-tree').setup {
      sync_root_with_cwd = true,
      select_prompts = true,
      on_attach = on_attach,
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
