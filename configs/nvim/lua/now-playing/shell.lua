local M = {}

M.file_path = function (...)
  -- Path to this source file, removing the leading '@'
  local source = string.sub(debug.getinfo(1, "S").source, 2)

  -- Path to the package root
  return table.concat({
    vim.fn.fnamemodify(source, ":p:h"),
    ...
  }, '/')
end

M.cmd = function (command, ...)
  return {
    cmd = command,
    opts = {
      args = { ... }
    }
  }
end

M.run = function (command, sin, callback)
  if not callback then
    callback = sin
    sin = nil
  end
  local luv = vim.loop

  local stdin = nil
  if sin then
    stdin = luv.new_pipe()
  end
  local stdout = luv.new_pipe()
  local stderr = luv.new_pipe()
  local out = ''
  local err = ''
  local handle

  command.opts.stdio = { stdin, stdout, stderr }
  handle = luv.spawn(command.cmd, command.opts, function (code, signal)
    if code ~= 0 then
      luv.read_stop(stdout)
      luv.read_stop(stderr)
    end
    if stdin then
      luv.shutdown(stdin)
      luv.close(stdin)
    end
    luv.close(stdout)
    luv.close(stderr)
    luv.close(handle)
    vim.defer_fn(function ()
      callback { code = code, signal = signal, stdout = out, stderr = err }
    end, 0)
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
  if stdin then
    luv.write(stdin, sin)
  end
end

return M
