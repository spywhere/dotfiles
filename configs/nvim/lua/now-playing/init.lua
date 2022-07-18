local M = {}
local P = {
  enable = false,
  players = {
    'mpd',
    'applescript',
    'cscript'
  },
  data = nil
}

P.iterate = function (list, callback)
  local index = 0

  local function next()
    index = index + 1
    if index > #list then
      return
    end

    local ok, error = pcall(function ()
      local ran, code = vim.wait(P.timeout, function ()
        callback(list[index], next)
        return true
      end)

      if code == -1 then
        -- callback is stuck, skip it
        next()
      end
    end)

    if not ok then
      print('error while iterating #'.. index .. ':', error)
    end
  end

  next()
end

P.fetch = function ()
  P.iterate(P.players, function (name, next)
    local player = require('now-playing.players.' .. name)

    player.get_data(function (data)
      if not data or type(data) ~= 'table' then
        next()
        return
      end

      data.last_update = os.time()

      P.data = data
    end, require('now-playing.shell'))
  end)

  local interval = P.polling_interval
  if M.is_playing() then
    interval = P.playing_interval
  end
  if P.enable and interval > 0 then
    vim.defer_fn(P.fetch, interval)
  end
end

M.get = function (key)
  if not M.is_running() then
    return nil
  end

  return P.data[key]
end

M.remote = function ()
  -- send remote command
end

M.is_running = function ()
  return P.data ~= nil
end

M.is_playing = function ()
  return M.is_running() and P.data.state == 'playing'
end

M.format = function (fn, ...)
  if type(fn) == 'string' then
    local args = { ... }
    return M.format(function (format)
      return format().format(fn, unpack(args))
    end)
  elseif type(fn) == 'function' then
    local format = require('now-playing.format')
    return fn(format).build(M.get('position'), M.get)
  else
    return string.format(
      'invalid format: expected \'string\' or \'function\', got \'%s\'',
      type(fn)
    )
  end
end

M.debug = function ()
  if not M.is_running() then
    return 'not running'
  end
  return vim.inspect(P.data, { newline = '', indent='' })
end

M.enable = function ()
  local has_enable = P.enable
  P.enable = true
  if not has_enable then
    P.fetch()
  end
end

M.disable = function ()
  P.enable = false
end

M.status = function (format)
  return format()
    .format(
      '%s ',
      format()
        .map('state', {
          playing = '▶'
        }, ' ')
    )
    .scrollable(
      25,
      '%s - %s',
      'artist',
      'title'
    )
    .format(
      ' [%s/%s]',
      format().duration('position'),
      format().duration('duration')
    )
end

M.setup = function (options)
  local opts = options or {}

  opts = vim.tbl_extend('keep', opts, {
    polling_interval = 5000,
    playing_interval = 1000,
    timeout = 100,
    autostart = true
  })

  P.polling_interval = opts.polling_interval
  P.playing_interval = opts.playing_interval
  P.timeout = opts.timeout

  if opts.autostart then
    M.enable()
  end
end

return M
