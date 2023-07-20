local cache = require('lib.cache')

local P = {
  cache_key = 'filter_folder',
  bufid = nil,
  winid = nil,
  manual = false
}
local M = {}

M.refresh = function ()
  if P.bufid == nil then
    return false
  end

  local filters = vim.tbl_values(cache.get('filter_folder', {}))
  vim.api.nvim_buf_set_lines(
    P.bufid, 1, -1, false,
    vim.tbl_map(function (v) return '  ' .. v end, filters)
  )

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
    style = 'minimal'
  })

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

M.clear = function ()
  cache.del(P.cache_key)
end

M.toggle_item = function (item, display_name)
  local folders = cache.get(P.cache_key, {})
  if folders[item] then
    folders[item] = nil
  else
    folders[item] = display_name
  end
  cache.set(P.cache_key, folders)
end

M.cycle_item = function (item, display_name)
  local folders = cache.get(P.cache_key, {})
  if folders['!' .. item] then
    folders['!' .. item] = nil
  elseif folders[item] then
    folders[item] = nil
    folders['!' .. item] = '!' .. display_name
  else
    folders[item] = display_name
  end
  cache.set(P.cache_key, folders)
end

M.setup = function (options)
  local opts = vim.tbl_extend('force', {
    title = 'Filters:'
  }, options or {})
  P.bufid = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(P.bufid, 0, 1, false, { opts.title })
  M.refresh()
end

return M
