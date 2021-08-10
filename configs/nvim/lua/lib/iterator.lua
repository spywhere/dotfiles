local M = {}

M.recurse = function (fn)
  return (function (next) return next(next) end)(fn)
end

M.generator = function (fn, default)
  return M.recurse(function (next)
    return function (value)
      return fn(next(next), value)
    end
  end)(default)
end

M.make_table = function (base)
  return M.generator(function (next, items)
    return function (key)
      if key == nil then
        return items
      end

      return function (value)
        items[key] = value
        return next(items)
      end
    end
  end, base or {})
end

M.each = function (fn)
  return M.generator(function (next)
    return function (value)
      fn(value)
      return next()
    end
  end)
end

return M
