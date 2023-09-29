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

local proxy = function (_)
  local function proxy_to_options(map)
    return function (_, options, _, plugin)
      local function proxy_key(from, to)
        if not plugin[from] then
          return
        end

        local value = plugin[from]
        local to_key = to
        if type(to_key) == 'function' then
          to_key = to_key(value)
        end
        options[to_key] = value
      end

      for from, to in pairs(map) do
        proxy_key(from, to)
      end
    end
  end

  return function (hook, ctx)
    local map = {}
    if ctx.backend == 'vim-plug' then
      map = {
        branch = 'branch',
        tag = 'tag',
        commit = 'commit',
        run = 'do',
        cmd = 'on',
        ft = 'for'
      }
    elseif ctx.backend == 'packer.nvim' then
      map = {
        branch = 'branch',
        tag = 'tag',
        commit = 'commit',
        run = 'run',
        cmd = 'cmd',
        ft = 'ft'
      }
    elseif ctx.backend == 'lazy.nvim' then
      map = {
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
    end

    hook('plugin_options', proxy_to_options(map))
  end
end

M.setup = function ()
  local plug = require('plug')
  plug.setup {
    backend = plug.backend.lazy {},
    extensions = {
      proxy {},
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
