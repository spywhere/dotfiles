local M = {}
local P = {}

M.set = function (key, value)
  P[key] = value
end

M.has = function (key)
  return P[key] ~= nil
end

M.get = function (key, default_value)
  if M.has(key) then
    return P[key]
  else
    return default_value
  end
end

M.del = function (key)
  M.set(key, nil)
end

return M
