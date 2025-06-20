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
  LSPM.experiment = function (expid)
    return {
      on = function ()
        lsps[name].experiment = vim.tbl_extend('force', lsps[name].experiment or {}, {
          [expid] = true
        })
        return LSPM
      end,
      off = function ()
        lsps[name].experiment = vim.tbl_extend('force', lsps[name].experiment or {}, {
          [expid] = false
        })
        return LSPM
      end
    }
  end
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

local all_lsp_on_attach = function (client, bufnr)
  for _, cfn in ipairs(fns.attach) do
    cfn(client, bufnr)
  end
end

local lsp_on_attach = function (fn)
  return function (client, bufnr)
    if type(fn) == 'function' then
      fn(client, bufnr)
    end

    all_lsp_on_attach(client, bufnr)
  end
end

local check_experiment = function (exps, name)
  for exp, enabled in pairs(exps) do
    print('[' .. name .. ']Checking experiment: ' .. exp .. ' with value: ' .. tostring(enabled) .. ' got ' .. tostring(registry.experiment(exp).on()))
    if registry.experiment(exp).on() ~= enabled then
      return false
    end
  end
  return true
end

local setup_lsp = function (name, lsp, options)
  if
    (options and options.skip_check) or
    (lsp.executable and fn.executable(lsp.executable) == 0) or
    (lsp.experiment and not check_experiment(lsp.experiment, name))
  then
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
  if fn.has('nvim-0.11') == 1 then
    vim.lsp.config(name, lsp_options)
    vim.lsp.enable(name)
  else
    local nvim_lsp = require('lspconfig')
    nvim_lsp[name].setup(lsp_options)
  end
end

local M = {}
local has_been_setup = false

local function setup(setup_fn)
  if has_been_setup then
    return
  end
  assert(not has_been_setup, 'LSP setup has already been called')

  setup_fn()

  for _, fn in ipairs(fns.setup) do
    fn()
  end
  fns.setup = {}
  has_been_setup = true
end

M.setup = function (name)
  if type(name) == 'function' then
    -- return a setup function with a handler
    return function ()
      return setup(function ()
        local function handler(server, options)
          if lsps[server] then
            setup_lsp(server, lsps[server], options)
          end
        end
        name(handler, vim.tbl_keys(lsps))
      end)
    end
  elseif name == nil then
    return setup(function ()
      -- perform a setup for LSPs
      for lsp_name, lsp in pairs(lsps) do
        setup_lsp(lsp_name, lsp)
      end
    end)
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
