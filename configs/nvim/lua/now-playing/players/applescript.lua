local M = {}

M.get_data = function (callback, shell)
  if vim.fn.has('mac') == 0 then
    -- applescript only available on macOS
    return callback()
  end

  if vim.fn.executable('osascript') == 0 then
    -- osascript must be executable
    return callback()
  end

  local cmd = shell.cmd(
    'osascript',
    '-l',
    'JavaScript',
    shell.file_path('players/applescript.js')
  )
  shell.run(cmd, function (result)
    local output = result.stdout
    if output == '' then
      return callback()
    end

    local parts = vim.split(output, '\n', { plain = true })

    if parts[1] == 'stopped' then
      return callback()
    end

    callback({
      state = parts[1],
      position = tonumber(parts[2]),
      duration = tonumber(parts[3]),
      title = parts[4],
      artist = parts[5],
      app = parts[6]
    })
  end)
end

return M
