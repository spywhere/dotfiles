local M = {}

M.get_data = function (callback, shell)
  if vim.fn.executable('nc') == 0 then
    -- nc must be executable
    return callback()
  end

  local cmd = shell.cmd(
    'nc',
    '127.0.0.1',
    '6600'
  )

  local is_running = function (cb)
    shell.run(cmd, 'close\n', function (result)
      local output = result.stdout
      if not string.find(output, 'OK MPD') then
        return callback()
      end

      cb()
    end)
  end

  local get_status = function ()
    shell.run(cmd, 'status\ncurrentsong\nclose\n', function (result)
      local output = result.stdout
      if output == '' then
        return callback()
      end

      local parts = vim.split(output, '\n', { plain = true })
      local data = {}

      local prefixed = function (text, prefix)
        return string.sub(text, 1, #prefix) == prefix, string.sub(text, #prefix +1 )
      end

      for _, value in ipairs(parts) do
        local has_prefix, rest = prefixed(value, 'state: ')
        if has_prefix then
          if rest == 'play' then
            data.state = 'playing'
          elseif rest == 'pause' then
            data.state = 'paused'
          elseif rest == 'stop' then
            return callback()
          end
        end

        has_prefix, rest = prefixed(value, 'time: ')
        if has_prefix then
          local times = vim.split(rest, ':')
          data.position = tonumber(times[1])
          data.duration = tonumber(times[2])
        end

        has_prefix, rest = prefixed(value, 'Title: ')
        if has_prefix then
          data.title = rest
        end

        has_prefix, rest = prefixed(value, 'Artist: ')
        if has_prefix then
          data.artist = rest
        end
      end

      return callback(data)
    end)
  end

  is_running(get_status)
end

return M
