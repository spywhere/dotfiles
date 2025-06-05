local bindings = require('lib.bindings')
local registry = require('lib.registry')
local filter = require('plugin.explorer._filter')

local update_filter_folder = function ()
  local api = require('nvim-tree.api')
  local node = api.tree.get_node_under_cursor()
  if node.name == '..' then
    filter.clear()
    return not filter.refresh() and filter.close(true)
  elseif not node.fs_stat then
    return
  end

  local item = vim.fn.fnamemodify(node.absolute_path, ':.')
  local type = node.fs_stat.type

  if type == 'directory' then
    filter.cycle_item(item .. '/**')
  elseif type == 'file' then
    filter.cycle_item(item)
  else
    return
  end

  return filter.refresh() and filter.open(true) or filter.close(true)
end

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'f', update_filter_folder, opts('Update filters'))
  vim.keymap.set('n', 'F', function () filter.toggle_focus() end, opts('Toggle filters'))
  vim.keymap.set('n', '<C-j>', function () filter.toggle_focus() end, opts('Toggle filters'))
  vim.keymap.set('n', '?', api.live_filter.start, opts('Start live filter'))
  vim.keymap.set('n', '<C-c>', api.live_filter.clear, opts('Stop live filter'))
end

registry.install {
  'nvim-tree/nvim-tree.lua',
  skip = registry.experiment('explorer').not_be('tree'),
  defer = function ()
    if registry.experiment('explorer').is_not('tree') then
      return
    end
    bindings.map.all('<leader>E', '<cmd>NvimTreeFocus<cr>')

    bindings.map.all('<leader>e', function ()
      local tree = prequire('nvim-tree.api')
      if not tree then
        return
      end
      tree = tree.tree

      if tree.is_visible() and not tree.is_tree_buf(0) then
        tree.focus()
      else
        tree.toggle()
      end
    end)
  end,
  delay = function ()
    local tree = prequire('nvim-tree')
    if not tree then
      return
    end
    tree.setup {
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
      },
      git = {
        enable = false,
      },
      filesystem_watchers = {
        ignore_dirs = { 'node_modules', '.git' }
      }
    }

    filter.setup {}

    local api = require('nvim-tree.api')
    local Event = api.events.Event

    api.events.subscribe(Event.TreeOpen, function ()
      return filter.refresh() and filter.open(true)
    end)
    api.events.subscribe(Event.TreeClose, function ()
      return filter.reset()
    end)
  end
}
