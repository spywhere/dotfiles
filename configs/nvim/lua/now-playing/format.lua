return function ()
  local F = {}
  local text_components = {}

  local set = function (tbl, key, val)
    if not tbl then
      return {
        [key] = value
      }
    end
    tbl[key] = val
    return tbl
  end

  local raw_wrap = function (fn)
    return function (...)
      local args = { ... }
      table.insert(text_components, function (time, getter, state)
        return fn(time, getter, state, unpack(args))
      end)

      return F
    end
  end

  local wrap = function (fn)
    return raw_wrap(function (time, getter, _, ...)
      return fn(time, getter, ...)
    end)
  end

  local raw_format = function (time, getter, state, format, ...)
    local components = vim.tbl_map(function (key)
      if type(key) == 'table' and key.build then
        return key.build(time, getter, state)
      end

      return getter and getter(key) or ''
    end, { ... })
    return string.format(format, unpack(components))
  end

  local scroll = function (text, offset, length)
    local text_length = #text
    if text_length < length then
      return text
    end

    local adjusted_offset = offset % text_length
    local output = string.sub(
      text,
      adjusted_offset + 1,
      math.min(adjusted_offset + length, text_length)
    )

    local remaining = length - #output
    while remaining > 0 do
      if text_length <= remaining then
        output = output .. text
      else
        output = output .. string.sub(
          text,
          1,
          remaining
        )
      end
      remaining = length - #output
    end

    return output
  end

  F.scrollable = raw_wrap(function (time, getter, state, length, format, ...)
    if state and state.force then
      return raw_format(time, getter, state, format, ...)
    end

    local whole = raw_format(time, getter, set(state, 'force', true), format, ...)
    if #whole < length then
      return whole
    end

    local components = { ... }
    local separator = '   '
    local max_scrollable = (#components) * length
    if max_scrollable < #whole then
      -- scroll each component
      local text_components = vim.tbl_map(function (key)
        if type(key) == 'table' and key.build then
          return scroll(
            key.build(time, getter, state) .. separator,
            time,
            length
          )
        end

        return getter and scroll(getter(key), time, length) or ''
      end, { ... })
      return string.format(format, unpack(text_components))
    else
      return scroll(whole .. separator, time, length)
    end
  end)

  F.format = raw_wrap(raw_format)

  F.time = wrap(function (_, getter, format, key)
    local number = key

    if getter and type(key) == 'string' then
      number = getter(key)
    end
    if type(number) ~= 'number' then
      number = 0
    end

    return os.date(format, number)
  end)

  F.duration = wrap(function (_, getter, key)
    local number = key

    if getter and type(key) == 'string' then
      number = getter(key)
    end
    if type(number) ~= 'number' then
      number = 0
    end

    minutes = number / 60
    seconds = number % 60
    return string.format('%02d:%02d', minutes, seconds)
  end)

  F.static = wrap(function (_, _, _, text)
    return text
  end)

  F.build = function (time, getter, state)
    local components = vim.tbl_map(function (component)
      return component(time, getter, state)
    end, text_components)

    return table.concat(components, '')
  end

  return F
end
