-- NOTE: This require 'nvim-dap' to be installed
local daps = {}

local generate_dap_setup = function (name)
  if not daps[name] then
    daps[name] = {
      options = {}
    }
  end

  local DAPM = {}

  local wrap = function (fn)
    return function (...)
      fn(...)
      return DAPM
    end
  end

  DAPM.adapter = wrap(function (adapter)
    table.insert(daps[name].options, adapter)
  end)
  DAPM.executable = wrap(function (name, args)
    table.insert(daps[name].options, function ()
      local name = name
      local args = args

      if type(name) == 'function' then
        name = name()
      end

      return {
        type = 'executable',
        name = name,
        args = args
      }
    end)
  end)
  DAPM.server = wrap(function (host, port)
    table.insert(daps[name].options, function ()
      local host = host
      local port = port

      if type(host) == 'function' then
        host, port = host()
      end

      return {
        type = 'server',
        host = host,
        port = port
      }
    end)
  end)

  DAPM.ft = wrap(function (filetypes, ...)
    if type(filetypes) ~= 'table' then
      filetypes = { filetypes }
    end
    if not daps[name].filetypes then
      daps[name].filetypes = {}
    end
    local configs = { ... }
    daps[name].filetypes = filetypes
    daps[name].configs = configs
  end)

  return DAPM
end

local setup_dap = function (name, adapter, setter)
  local dap_setter = {
    adapter = function (dap_name, dap_adapter)
      local dap = require('dap')
      dap.adapters[dap_name] = dap_adapter
    end,
    config = function (filetype, config)
      local dap = require('dap')
      if dap.configurations[filetype] then
        table.insert(dap.configurations[filetype], config)
      else
        dap.configurations[filetype] = { config }
      end
    end
  }

  if not setter then
    setter = dap_setter
  end
  if not setter.adapter then
    setter.adapter = dap_setter.adapter
  end
  if not setter.config then
    setter.config = dap_setter.config
  end

  local dap_adapter = {}

  for _, option in ipairs(adapter.options) do
    if type(option) == 'function' then
      option = option()
    end
    dap_adapter = vim.tbl_extend('force', dap_adapter, option)
  end

  setter.adapter(name, dap_adapter)

  if adapter.configs then
    for _, filetype in ipairs(adapter.filetypes) do
      for _, config in ipairs(adapter.configs) do
        if type(config) == 'function' then
          config = config()
        end
        config.type = name
        setter.config(filetype, config)
      end
    end
  end
end

local M = {}
local has_been_setup = false

local function setup(setup_fn)
  if has_been_setup then
    return
  end
  assert(not has_been_setup, 'DAP setup has already been called')

  setup_fn()

  has_been_setup = true
end

M.setup = function (name)
  if type(name) == 'function' then
    -- return a setup function with a handler
    return function ()
      local function handler(dap_name, setter)
        if daps[dap_name] then
          setup_dap(dap_name, daps[dap_name], setter)
        end
      end
      return setup(function ()
        name(handler)
      end)
    end
  elseif name == nil then
    return setup(function ()
      -- perform a setup for DAPs
      for dap_name, adapter in pairs(daps) do
        setup_dap(dap_name, adapter)
      end
    end)
  else
    -- generate a chainable object for setting up DAP
    return generate_dap_setup(name)
  end
end

return M
