local M = {}

M.recurse = function (fn)
  vim.validate({
    fn = { fn, 'f' }
  })
  return (function (next) return next(next) end)(fn)
end

M.generator = function (fn, default)
  vim.validate({
    fn = { fn, 'f' }
  })
  return M.recurse(function (next)
    return function (value)
      return fn(next(next), value)
    end
  end)(default)
end

M.make_table = function (base, fn)
  vim.validate({
    base = { base, 't', true },
    fn = { fn, 'f', true }
  })
  return M.generator(function (next, items)
    return function (key)
      if key == nil then
        return items
      end

      return function (value)
        if fn then
          items = fn(items, value, key)
        else
          items[key] = value
        end
        return next(items)
      end
    end
  end, base or {})
end

M.apply_each = function (fn)
  vim.validate({
    fn = { fn, 'f' }
  })
  return M.generator(function (next)
    return function (value)
      fn(value)
      return next()
    end
  end)
end

return M
