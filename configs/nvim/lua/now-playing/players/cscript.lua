local M = {}

M.get_data = function (callback, shell)
  if vim.fn.has('win32') == 0 and vim.fn.has('wsl') == 0 then
    -- cscript only available on Windows / WSL
    return callback()
  end

  if vim.fn.executable('cscript.exe') == 0 then
    -- cscript must be executable
    return callback()
  end

  local cmd = shell.cmd(
    'cscript.exe',
    '//Nologo',
    shell.file_path('players/cscript.js')
  )
  shell.run(cmd, function (result)
    local output = string.gsub(result.stdout, '\r', '')
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
