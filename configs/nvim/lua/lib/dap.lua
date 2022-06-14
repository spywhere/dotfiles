local adapters = {}
local dap_configs = {}

local generate_dap_setup = function (name)
  if not adapters[name] then
    adapters[name] = {}
  end

  local DAPM = {}

  local wrap = function (fn)
    return function (...)
      fn(...)
      return DAPM
    end
  end

  DAPM.adapter = wrap(function (adapter)
    adapters[name] = adapter
  end)
  DAPM.executable = wrap(function (name, args)
    local name = name
    local args = args

    if type(name) == 'function' then
      name = name()
    end

    adapters[name] = {
      type = 'executable',
      name = name,
      args = args
    }
  end)
  DAPM.server = wrap(function (host, port)
    local host = host
    local port = port

    if type(host) == 'function' then
      host, port = host()
    end

    adapters[name] = {
      type = 'server',
      host = host,
      port = port
    }
  end)

  DAPM.ft = wrap(function (filetypes, ...)
    if type(filetypes) ~= 'table' then
      filetypes = { filetypes }
    end
    for _, filetype in ipairs(filetypes) do
      if not dap_configs[filetype] then
        dap_configs[filetype] = {}
      end
      local configs = { ... }
      for _, config in ipairs(configs) do
        if type(config) == 'function' then
          config = config()
        end
        config.type = name
        table.insert(dap_configs[filetype], config)
      end
    end
  end)

  return DAPM
end

local M = {}
local has_been_setup = false

M.setup = function (name)
  if name == nil then
    assert(not has_been_setup, 'DAP setup has already been called')

    local dap = require('dap')

    for name, adapter in pairs(adapters) do
      dap.adapters[name] = adapter
    end
    for filetype, configs in pairs(dap_configs) do
      dap.configurations[filetype] = configs
    end
  else
    return generate_dap_setup(name)
  end
end

return M
