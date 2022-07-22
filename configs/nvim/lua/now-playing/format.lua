return function ()
  local F = {}
  local text_components = {}

  local prequire = function (...)
    local status, mod = pcall(require, ...)
    if status then
      return mod
    else
      return nil
    end
  end

  local substr = string.sub
  local strlen = string.len
  local utf8 = prequire('utf8')
  if utf8 then
    substr = function (text, begin_index, end_index)
      local length = utf8.len(text)
      local end_offset = string.len(text)

      if end_index < length then
        end_offset = utf8.offset(text, end_index + 1) - 1
      end

      return string.sub(text, utf8.offset(text, begin_index), end_offset)
    end
    strlen = function (text)
      return utf8.len(text)
    end
  end

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

  local scroll = function (text, offset, length, separator)
    local text_length = strlen(text)
    if text_length < length then
      return text, false
    end

    local adjusted_offset = offset % text_length
    local output = substr(
      text,
      adjusted_offset + 1,
      math.min(adjusted_offset + 1 + length, text_length)
    )

    local remaining = length - strlen(output)
    while remaining > 0 do
      output = output .. (separator or '')
      if text_length <= remaining then
        output = output .. text
      else
        output = output .. substr(
          text,
          1,
          remaining
        )
      end
      remaining = length - strlen(output)
    end

    return output, true
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

    local scrollable = 0
    local text_components = {}

    for _, key in ipairs(components) do
      local raw_text = ''
      if type(key) == 'table' and key.build then
        raw_text = key.build(time, getter, state)
      elseif getter then
        raw_text = getter(key) or ''
      end

      local text, is_scroll = scroll(raw_text, time, length, separator)

      table.insert(text_components, text)

      if is_scroll then
        scrollable = scrollable + 1
      end
    end

    if scrollable < #components then
      return string.format(format, unpack(text_components))
    else
      local text = scroll(whole, time, length * (#components), separator)
      return text
    end
  end)

  F.format = raw_wrap(raw_format)

  F.map = wrap(function (_, getter, key, map, def)
    local raw_text = ''
    if type(key) == 'table' and key.build then
      raw_text = key.build(time, getter, state)
    elseif getter then
      raw_text = getter(key) or ''
    end

    return map[raw_text] or def
  end)

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

  F.static = wrap(function (_, _, text)
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
