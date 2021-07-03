local logger = require('lib/logger')

local M = {}

M.iterate_commands = function (commands, success, index)
  if index == nil then
    index = 1
  end
  if index == vim.tbl_count(commands) + 1 then
    if success and type(success) == 'string' then
      vim.cmd('redraw')
      vim.cmd('echo ' .. string.format('%q', success))
    end
    return
  end

  local command = commands[index]

  if command.message then
    vim.cmd('redraw')
    vim.cmd('echo ' .. string.format('%q', command.message))
  end

  if type(command.command) == 'function' then
    local ok, error = pcall(command.command)
    if ok then
      M.iterate_commands(commands, success, index + 1)
    else
      logger.error(command.error ..'\n'..vim.inspect(error))
      return
    end
  else
    local handle
    handle = luv.spawn(
      command.command,
      command.options,
      vim.schedule_wrap(function(code)
        handle:close()
        if code ~= 0 then
          local execute_cmd = command.command
          if command.options and command.options.args then
            execute_cmd = string.format(
              '%s %s', execute_cmd, table.concat(command.options.args, ' ')
            )
          end
          logger.error(string.gsub(command.error, '<msg>', execute_cmd) ..'\n')
        end
        M.iterate_commands(commands, success, index + 1)
      end)
    )
  end
end

return M
