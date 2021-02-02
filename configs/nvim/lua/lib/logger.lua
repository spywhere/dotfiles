local M = {}

M.info = function (message)
  api.nvim_write_out(message .. '\n')
end

M.error = function (message)
  api.nvim_err_write(message .. '\n')
end

return M
