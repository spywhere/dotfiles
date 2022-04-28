local M = {}

M.is_installed = function ()
  return vim.fn.filereadable(vim.fn.expand(plug_nvim_path)) ~= 0
end

M.install = function ()
  if vim.fn.executable('curl') == 0 then
    -- curl not installed, skip the config
    print('cannot install plug.nvim, curl is not installed')
    return false
  end
  vim.cmd(
    'silent !curl -fLo ' .. plug_nvim_path .. ' --create-dirs ' .. plug_nvim_url
  )
  return true
end

M.add = function (...)
  require('plug').install(...)
end

M.setup = function ()
  local plug = require('plug')
  plug.setup {
    plugin_dir = plugin_home,
    extensions = {
      plug.extension.auto_install {},
      plug.extension.priority {},
      plug.extension.skip {},
      plug.extension.setup {},
      plug.extension.config {},
      plug.extension.defer {}
    }
  }
end

return M
