local logger = require('lib.logger')

local M = {}

M.explore = function (dir, recurse)
  local handle = luv.fs_scandir(lua_home .. '/' .. dir)
  if handle == nil then
    return
  elseif type(handle) == 'string' then
    logger.error(handle)
    return
  end

  local dirs = {}
  while true do
    local name, item_type = luv.fs_scandir_next(handle)
    if not name then
      break
    end

    if item_type == 'file' and string.sub(name, 1, 1) ~= '_' then
      local path = dir .. '/' .. string.gsub(name, '[.]lua$', '')
      require('' .. string.gsub(path, '[/\\]', '.'))
    elseif item_type == 'directory' and recurse == true then
      -- load subdirectory as well, but do it last
      table.insert(dirs, dir .. '/' .. name)
    end
  end

  for _, path in ipairs(dirs) do
    M.explore(path, recurse)
  end
end

return M
