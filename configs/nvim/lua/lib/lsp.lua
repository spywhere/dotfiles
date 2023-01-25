-- NOTE: This require 'lspconfig' to be installed
local registry = require('lib.registry')

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

  local set = function (key)
    return function (value)
      lsps[name][key] = value
      return LSPM
    end
  end

  LSPM.filetypes = set('filetypes')
  LSPM.auto = set('auto')
  LSPM.need_executable = set('executable')
  LSPM.prepare = set('prepare')
  LSPM.command = set('cmd')
  LSPM.options = set('options')
  LSPM.config = set('config')
  LSPM.root = set('root')
  LSPM.on = {
    setup = set('on_setup'),
    attach = set('on_attach')
  }

  return LSPM
end

local lsp_on_attach = function (fn)
  return function (client, bufnr)
    if type(fn) == 'function' then
      fn(client, bufnr)
    end

    for _, cfn in ipairs(fns.attach) do
      cfn(client, bufnr)
    end
  end
end

local setup_lsp = function (name, lsp)
  if lsp.executable and fn.executable(lsp.executable) == 0 then
    return
  end

  local lsp_options = lsp.options or {}

  if type(lsp.options) == 'function' then
    lsp_options = lsp_options()
  end

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

  local nvim_lsp = require('lspconfig')
  local nvim_lsp_util = require('lspconfig.util')
  local nvim_lsp_config = require('lspconfig.configs')

  if lsp.root then
    if type(lsp.root) == 'function' then
      lsp_options.root_dir = lsp.root
    else
      lsp_options.root_dir = nvim_lsp_util.root_pattern(unpack(lsp.root))
    end
  end

  lsp_options.on_attach = lsp_on_attach(lsp.on_attach)

  if type(lsp.on_setup) == 'function' then
    lsp.on_setup()
  end

  if lsp.auto then
    registry.auto('FileType', function ()
      lsp.auto(lsp_options)
    end, lsp.filetypes)
    return
  end

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
    return (cmp_lsp.default_capabilities or cmp_lsp.update_capabilities)(capabilities, override)
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
