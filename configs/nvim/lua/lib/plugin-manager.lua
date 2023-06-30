local M = {}

M.is_installed = function ()
  return fn.filereadable(vim.fn.expand(plug_nvim_path)) ~= 0
end

M.install = function ()
  if fn.executable('curl') == 0 then
    -- curl not installed, skip the config
    print('cannot install plug.nvim, curl is not installed')
    return false
  end
  vim.cmd(
    'silent !curl -fLo ' .. plug_nvim_path .. ' --create-dirs ' .. plug_nvim_url
  )

  vim.cmd('packadd! plug.nvim')

  return true
end

M.add = function (...)
  require('plug').install(...)
end

M.setup = function ()
  local plug = require('plug')
  plug.setup {
    backend = 'packer.nvim',
    options = {
      display = {
        open_fn = function ()
          return require('packer.util').float({ border = 'single' })
        end
      }
    },
    extensions = {
      plug.extension.auto_install {},
      plug.extension.priority {
        priority = ''
      },
      plug.extension.skip {},
      plug.extension.requires {},
      plug.extension.setup {},
      plug.extension.config {},
      plug.extension.defer {}
    }
  }
end

return M
