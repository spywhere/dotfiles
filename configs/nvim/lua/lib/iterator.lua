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

M.lazy = function (items)
  local C = {
    forward = true,
    keep_order = false,
    items = items,
    chains = {}
  }

  local forward_iter = function (t, idx)
    idx = idx + 1
    if idx ~= #t + 1 then
      return idx, t[idx]
    end
  end
  local backward_iter = function (t, idx)
    idx = idx - 1
    if idx ~= 0 then
      return idx, t[idx]
    end
  end
  local directional_ipairs = function (t, forward)
    if forward then
      return forward_iter, t, 0
    else
      return backward_iter, t, #t + 1
    end
  end

  local function apply(valid, fn, ...)
    if valid then
      return fn(C.ctx, ...)
    else
      return fn(...)
    end
  end

  local function evaluate_chain(chains, value, key, list)
    local skip = false
    local output = value
    local valid = false

    for _, v in ipairs(chains) do
      if v.op == 'map' then
        output, skip = apply(valid, v.fn, output, key, list)
      elseif v.op == 'context' then
        if v.fn then
          C.ctx = v.fn(C.ctx, output, key, list)
          valid = true
        else
          C.ctx = nil
          valid = false
        end
      elseif v.op == 'filter' and not apply(valid, v.fn, output, key, list) then
        return true, nil
      end
    end

    if skip == nil then
      return false, output
    else
      return skip, output
    end
  end

  C.context = function (...)
    for _, fn in ipairs({...}) do
      table.insert(C.chains, {
        op = 'context',
        fn = fn
      })
    end
    return C
  end

  C.map = function (...)
    for _, fn in ipairs({...}) do
      table.insert(C.chains, {
        op = 'map',
        fn = fn
      })
    end
    return C
  end

  C.filter = function (...)
    for _, fn in ipairs({...}) do
      table.insert(C.chains, {
        op = 'filter',
        fn = fn
      })
    end
    return C
  end

  C.reverse = function (value)
    if value == nil then
      C.forward = not C.forward
    else
      C.forward = not value
    end
    return C
  end

  C.ordered = function (value)
    if value == nil then
      C.keep_order = true
    else
      C.keep_order = value
    end
    return C
  end

  C.take = function (itms, count)
    local output = {}

    if not itms or type(itms) == 'number' then
      count = itms
      itms = C.items or {}
    end

    local size = #itms
    for k, v in directional_ipairs(itms, C.forward) do
      if C.keep_order and not C.forward then
        k = size - k + 1
      end
      local skip, value = evaluate_chain(C.chains, v, k, itms)
      if not skip then
        if C.keep_order and not C.forward then
          table.insert(output, 1, value)
        else
          table.insert(output, value)
        end

        if count ~= nil and #output == count then
          break
        end
      end
    end

    return output
  end

  C.get = function (itms) return C.take(itms) end

  C.pipe = function (v, k, itms)
    local skip, value = evaluate_chain(C.chains, v, k, itms)
    return value, skip
  end

  return C
end

return M
