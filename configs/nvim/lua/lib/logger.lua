local M = {}

local log = function (severity)
  return function (message)
    vim.notify(message .. '\n', severity)
  end
end

return {
  error = log(vim.log.levels.ERROR),
  warn = log(vim.log.levels.WARN),
  info = log(vim.log.levels.INFO),
  trace = log(vim.log.levels.TRACE),
  debug = log(vim.log.levels.DEBUG)
}
