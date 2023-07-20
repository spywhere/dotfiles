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
    if v == item then
      return i
    end
  end
  return nil
end

P.new = function (value, index)
  local records = cache.get(P.cache_key, {})
  if index == nil then
    table.insert(records, value)
  else
    table.insert(records, index, value)
  end
  cache.set(P.cache_key, records)
end

P.new_ui = function (index, direction)
  if index < 1 and direction < 1 then
    return
  end

  vim.ui.input({
    prompt = 'New Filter: '
  }, function (input)
    if input == nil then
      return
    end
    P.new(input, index + direction)
    M.refresh()
    vim.api.nvim_win_set_cursor(P.winid, { index + direction + 1, 0 })
  end)
end

P.update_ui = function (index)
  local records = cache.get(P.cache_key, {})
  vim.ui.input({
    prompt = 'New Filter: ',
    default = records[index]
  }, function (input)
    if input == nil then
      return
    end
    records[index] = input
    cache.set(P.cache_key, records)
    M.refresh()
  end)
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
  if string.sub(record, 1, 1) == '!' then
    if cycle_remove then
      return P.remove(index)
    end
    record = string.sub(record, 2)
  else
    record = '!' .. record
  end
  records[index] = record
  cache.set(P.cache_key, records)
end

P.keymap = function (mode, key, edit, action)
  if not action then
    vim.api.nvim_buf_set_keymap(P.bufid, mode, key, '', {
      noremap = true,
      silent = true
    })
    return
  end

  vim.api.nvim_buf_set_keymap(
    P.bufid, mode, key, '', {
      callback = function ()
        if edit == nil or edit == false then
          action()
        else
          local row = vim.api.nvim_win_get_cursor(P.winid)[1]
          if row < 2 and type(edit) == 'boolean' then
            return
          end
          local index = row - 1
          action(index)
          M.refresh()
        end
      end,
      noremap = true,
      silent = true
    }
  )
end

M.get = function ()
  return cache.get(P.cache_key, {})
end

M.refresh = function ()
  if P.bufid == nil then
    return false
  end

  local filters = M.get()
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

  vim.cmd('20split')
  P.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(P.winid, P.bufid)
  vim.api.nvim_set_current_win(treewin)

  vim.api.nvim_buf_set_option(P.bufid, 'modifiable', false)
  vim.api.nvim_buf_set_option(P.bufid, 'filetype', 'TreeFilter')
  vim.api.nvim_win_set_option(P.winid, 'cursorline', true)
  vim.api.nvim_win_set_option(P.winid, 'cursorcolumn', false)
  vim.api.nvim_win_set_option(P.winid, 'number', false)
  vim.api.nvim_win_set_option(P.winid, 'relativenumber', false)
  vim.api.nvim_win_set_option(P.winid, 'foldcolumn', '0')
  vim.api.nvim_win_set_option(P.winid, 'spell', false)
  vim.api.nvim_win_set_option(P.winid, 'list', false)
  vim.api.nvim_win_set_option(P.winid, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(P.winid, 'colorcolumn', '')
  vim.api.nvim_win_set_option(P.winid, 'statuscolumn', '')

  P.keymap('n', 'q', false, M.close)
  P.keymap('n', 'F', false, M.close)
  P.keymap('n', 'f', true, P.cycle)
  P.keymap('n', '<A-Up>', true, function (index) return P.reorder(index, -1) end)
  P.keymap('n', '<A-Down>', true, function (index) return P.reorder(index, 1) end)
  P.keymap('n', 'dd', true, P.remove)
  P.keymap('n', 'O', 0, function (index) return P.new_ui(index, 0) end)
  P.keymap('n', 'i', 0, function (index) return P.new_ui(index, 0) end)
  P.keymap('n', 'I', 0, function (index) return P.new_ui(index, 0) end)
  P.keymap('n', 'o', 0, function (index) return P.new_ui(index, 1) end)
  P.keymap('n', 'a', 0, function (index) return P.new_ui(index, 1) end)
  P.keymap('n', 'A', 0, function (index) return P.new_ui(index, 1) end)
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

M.cycle_item = function (item)
  local not_idx = P.find_item('!' .. item)
  local idx = P.find_item(item)
  if not_idx ~= nil then
    P.cycle(not_idx, true)
  elseif idx ~= nil then
    P.cycle(idx, true)
  else
    P.new(item)
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
