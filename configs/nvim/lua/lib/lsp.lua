-- NOTE: This require 'lspconfig' to be installed
local bindings = require('lib/bindings')

local lsps = {}
local fns = {
  setup = {},
  attach = {}
}

local generate_lsp_setup = function (name)
  if lsps[name] == nil then
    lsps[name] = {}
  end

  local LSPM = {}

  local wrap = function (fn)
    return function (...)
      fn(...)
      return LSPM
    end
  end

  LSPM.need_executable = wrap(function (executable)
    lsps[name].executable = executable
  end)

  LSPM.prepare = wrap(function (fn)
    lsps[name].prepare = fn
  end)

  LSPM.command = wrap(function (command)
    lsps[name].cmd = command
  end)

  LSPM.options = wrap(function (options)
    lsps[name].options = options
  end)

  LSPM.config = wrap(function (config)
    lsps[name].config = config
  end)

  LSPM.on = {
    setup = wrap(function (fn)
      lsps[name].on_setup = fn
    end),
    attach = wrap(function (fn)
      lsps[name].on_attach = fn
    end)
  }

  return LSPM
end

local lsp_on_attach = function (fn)
  return function (client, bufnr)
    if type(fn) == 'function' then
      fn(client, bufnr)
    end

    for _, fn in ipairs(fns.attach) do
      fn(client, bufnr)
    end
  end
end

local setup_lsp = function (name, lsp)
  if lsp.executable and not bindings.executable(lsp.executable) then
    return
  end

  local lsp_options = lsp.options or {}

  local pre_value = lsp.prepare

  if type(pre_value) == 'function' then
    pre_value = pre_value()
  end

  if lsp.cmd then
    if type(lsp.cmd) == 'function' then
      lsp_options.cmd = lsp.cmd(pre_value)
    else
      lsp_options.cmd = lsp.cmd
    end
  end

  lsp_options.on_attach = lsp_on_attach(lsp.on_attach)

  if type(lsp.on_setup) == 'function' then
    lsp.on_setup()
  end

  local nvim_lsp = require('lspconfig')
  local nvim_lsp_config = require('lspconfig/configs')
  if not nvim_lsp_config[name] and lsp.config and next(lsp.config) then
    nvim_lsp_config[name] = lsp.config
  end
  nvim_lsp[name].setup(lsp_options)
end

local M = {}
local has_been_setup = false

M.setup = function (name)
  if name == nil then
    assert(not has_been_setup, 'LSP setup has already been called')

    -- perform a setup for LSPs
    for lsp_name, lsp in pairs(lsps) do
      setup_lsp(lsp_name, lsp)
    end

    for _, fn in ipairs(fns.setup) do
      fn()
    end
    fns.setup = {}
    has_been_setup = true
  else
    -- generate a chainable object for setting up LSP
    return generate_lsp_setup(name)
  end
end

M.capabilities = function (override)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local cmp_lsp = prequire('cmp_nvim_lsp')
  if cmp_lsp then
    return cmp_lsp.update_capabilities(capabilities, override)
  else
    return capabilities
  end
end

M.on_setup = function (fn)
  if has_been_setup then
    fn()
    return
  end

  table.insert(fns.setup, fn)
end

M.on_attach = function (fn)
  table.insert(fns.attach, fn)
end

return M
