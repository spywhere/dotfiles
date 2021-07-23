local logger = require('lib/logger')

local M = {}

M.explore = function (dir, recurse)
  local handle = luv.fs_scandir(lua_home .. '/' .. dir)
  if type(handle) == 'string' then
    logger.error(handle)
    return
  end

  while true do
    local name, item_type = luv.fs_scandir_next(handle)
    if not name then
      break
    end

    if item_type == 'file' then
      require(dir .. '/' .. string.gsub(name, '[.]lua$', ''))
    elseif item_type == 'directory' and recurse == true then
      -- load subdirectory as well
      M.explore(dir .. '/' .. name, recurse)
    end
  end
end

return M
