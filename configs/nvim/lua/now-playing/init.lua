local M = {}
local S = {}
local P = {
  enable = false,
  players = {
    -- 'applescript', 'cscript', 'mpd'
    'cscript'
  },
  data = nil
}

S.file_path = function (...)
  -- Path to this source file, removing the leading '@'
  local source = string.sub(debug.getinfo(1, "S").source, 2)

  -- Path to the package root
  return table.concat({
    vim.fn.fnamemodify(source, ":p:h"),
    ...
  }, '/')
end

S.cmd = function (command, ...)
  return {
    cmd = command,
    opts = {
      args = { ... }
    }
  }
end

S.run = function (command, callback)
  local luv = vim.loop

  local stdout = luv.new_pipe()
  local stderr = luv.new_pipe()
  local out = ''
  local err = ''
  local handle

  command.opts.stdio = { nil, stdout, stderr }
  handle = luv.spawn(command.cmd, command.opts, function (code, signal)
    if code ~= 0 then
      luv.read_stop(stdout)
      luv.read_stop(stderr)
    end
    luv.close(stdout)
    luv.close(stderr)
    luv.close(handle)
    callback { code = code, signal = signal, stdout = out, stderr = err }
  end)

  luv.read_start(stdout, function (e, data)
    if data then
      out = out .. data
    end
  end)
  luv.read_start(stderr, function (e, data)
    if data then
      err = err .. data
    end
  end)
end

P.iterate = function (list, callback)
  local index = 1

  local function next()
    if index > #list then
      return
    end

    local ran, code = vim.wait(P.timeout, function ()
      callback(list[index], next)
      return true
    end)

    index = index + 1

    if code == -1 then
      -- callback is stuck, skip it
      next()
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
    end, S)
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

M.format = function ()
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

M.setup = function (options)
  local opts = options or {}

  opts = vim.tbl_extend('keep', opts, {
    polling_interval = 5000,
    playing_interval = 1000,
    timeout = 100
  })

  P.polling_interval = opts.polling_interval
  P.playing_interval = opts.playing_interval
  P.timeout = opts.timeout

  M.enable()
end

return M
