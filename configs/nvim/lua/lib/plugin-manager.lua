local M = {}

M.is_installed = function ()
  local is_installed = fn.filereadable(vim.fn.expand(plug_nvim_path)) ~= 0
  if is_installed then
    vim.cmd('packadd! plug.nvim')
  end
  return is_installed
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

local proxy_map = function (backend)
  if backend == 'vim-plug' then
    return {
      branch = 'branch',
      tag = 'tag',
      commit = 'commit',
      run = 'do',
      cmd = 'on',
      ft = 'for'
    }
  elseif backend == 'packer.nvim' then
    return {
      branch = 'branch',
      tag = 'tag',
      commit = 'commit',
      run = 'run',
      cmd = 'cmd',
      ft = 'ft'
    }
  elseif backend == 'lazy.nvim' then
    return {
      branch = 'branch',
      tag = function (value)
        if string.match(value, '*') then
          return 'version'
        else
          return 'tag'
        end
      end,
      commit = 'commit',
      run = 'build',
      cmd = 'cmd',
      ft = 'ft'
    }
  elseif backend == 'mini.deps' then
    return {
      branch = { 'checkout', 'monitor' },
      tag = { 'checkout', 'monitor' },
      commit = { 'checkout', 'monitor' },
      run = { hooks = 'post_checkout' }
    }
  end
end

M.setup = function ()
  local plug = require('plug')
  plug.setup {
    update_branch = 'develop',
    backend = plug.backend.lazy {},
    extensions = {
      plug.extension.proxy(proxy_map),
      plug.extension.auto_install {},
      plug.extension.skip {},
      plug.extension.requires {},
      plug.extension.setup {},
      plug.extension.config {},
      plug.extension.defer {}
    }
  }
end

return M
