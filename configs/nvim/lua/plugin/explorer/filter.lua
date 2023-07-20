local cache = require('lib.cache')

local M = {}
local P = {
  cache_key = 'filter_folder',
  bufid = nil,
  winid = nil,
  manual = false
}

P.set_lines = function (line, data)
  if P.bufid == nil then
    return
  end
  vim.api.nvim_buf_set_option(P.bufid, 'modifiable', true)
  vim.api.nvim_buf_set_lines(P.bufid, line, -1, false, data)
  vim.api.nvim_buf_set_option(P.bufid, 'modifiable', false)
end

P.find_item = function (item)
  local records = cache.get(P.cache_key, {})
  for i, v in ipairs(records) do
    if v.value == item then
      return i
    end
  end
  return nil
end

P.values = function ()
  return vim.tbl_map(
    function (v) return v.display_name end,
    cache.get(P.cache_key, {})
  )
end

P.new = function (value, display_name)
  local records = cache.get(P.cache_key, {})
  table.insert(records, { value = value, display_name = display_name })
  cache.set(P.cache_key, records)
end

P.remove = function (index)
  local records = cache.get(P.cache_key, {})
  if index < 1 or index > #records then
    return
  end
  table.remove(records, index)
  cache.set(P.cache_key, records)
end

P.reorder = function (index, direction)
  local records = cache.get(P.cache_key, {})
  local new_index = index + direction
  if new_index < 1 or new_index > #records then
    return
  end
  records[new_index], records[index] = records[index], records[new_index]
  vim.api.nvim_win_set_cursor(P.winid, { new_index + 1, 0 })
  cache.set(P.cache_key, records)
end

P.cycle = function (index, cycle_remove)
  local records = cache.get(P.cache_key, {})
  if index < 1 or index > #records then
    return
  end
  local record = records[index]
  if string.sub(record.value, 1, 1) == '!' then
    if cycle_remove then
      return P.remove(index)
    end
    record = {
      value = string.sub(record.value, 2),
      display_name = string.sub(record.display_name, 2)
    }
  else
    record = {
      value = '!' .. record.value,
      display_name = '!' .. record.display_name
    }
  end
  records[index] = record
  cache.set(P.cache_key, records)
end

P.keymap = function (mode, key, edit, action)
  if not action then
    vim.api.nvim_buf_del_keymap(P.bufid, mode, key, '')
    return
  end

  vim.api.nvim_buf_set_keymap(
    P.bufid, mode, key, '', {
      callback = function ()
        if edit then
          local row = vim.api.nvim_win_get_cursor(P.winid)[1]
          if row < 2 then
            return
          end
          local index = row - 1
          action(index)
          M.refresh()
        else
          action()
        end
      end,
      noremap = true,
      silent = true
    }
  )
end

M.get = function ()
  return vim.tbl_map(
    function (v) return v.value end,
    cache.get(P.cache_key, {})
  )
end

M.refresh = function ()
  if P.bufid == nil then
    return false
  end

  local filters = P.values()
  P.set_lines(1, vim.tbl_map(
    function (v) return '  ' .. v end, filters
  ))

  return #filters > 0
end

M.open = function (auto)
  if P.manual and auto then
    return false
  elseif not auto then
    P.manual = true
  end
  if P.bufid == nil then
    return false
  end
  if P.winid ~= nil then
    return true
  end

  local treewin = vim.api.nvim_get_current_win()
  P.winid = vim.api.nvim_open_win(P.bufid, false, {
    relative = 'win',
    height = 20,
    width = vim.api.nvim_win_get_width(treewin),
    col = 0,
    row = vim.api.nvim_win_get_height(treewin) - 20,
    style = 'minimal',
    focusable = true
  })
  vim.api.nvim_buf_set_option(P.bufid, 'modifiable', false)
  vim.api.nvim_buf_set_option(P.bufid, 'filetype', 'TreeFilter')
  vim.api.nvim_win_set_option(P.winid, 'cursorline', true)

  P.keymap('n', 'q', false, M.close)
  P.keymap('n', 'F', false, M.close)
  P.keymap('n', 'f', true, P.cycle)
  P.keymap('n', '<A-Up>', true, function (index) return P.reorder(index, -1) end)
  P.keymap('n', '<A-Down>', true, function (index) return P.reorder(index, 1) end)
  P.keymap('n', 'dd', true, P.remove)

  return true
end

M.close = function (auto)
  if P.manual and auto then
    return false
  end
  if P.winid == nil then
    return true
  end
  vim.api.nvim_win_close(P.winid, false)
  P.winid = nil

  return true
end

M.reset = function ()
  M.close()
  P.manual = false
end

M.toggle = function (auto)
  if P.winid == nil then
    return M.open(auto)
  else
    return M.close(auto)
  end
end

M.toggle_focus = function (auto)
  local bufid = vim.api.nvim_get_current_buf()
  if bufid == P.bufid then
    return M.close(auto)
  elseif P.winid == nil then
    return M.open(auto)
  else
    vim.api.nvim_set_current_win(P.winid)
  end
end

M.clear = function ()
  cache.del(P.cache_key)
end

M.cycle_item = function (item, display_name)
  local not_idx = P.find_item('!' .. item)
  local idx = P.find_item(item)
  if not_idx ~= nil then
    P.cycle(not_idx, true)
  elseif idx ~= nil then
    P.cycle(idx, true)
  else
    P.new(item, display_name)
  end
  M.refresh()
end

M.setup = function (options)
  local opts = vim.tbl_extend('force', {
    title = 'Filters:'
  }, options or {})
  P.bufid = vim.api.nvim_create_buf(false, true)
  P.set_lines(0, { opts.title })
  M.refresh()
end

return M
