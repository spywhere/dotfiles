-- NOTE: This require 'lspconfig' to be installed
local bindings = require('lib/bindings')
local registry = require('lib/registry')

local lsps = {}
local setups = {}

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

    if not client.resolved_capabilities.document_highlight then
      return
    end

    bindings.highlight.link('LspReferenceRead', 'CursorColumn')
    bindings.highlight.link('LspReferenceText', 'CursorColumn')
    bindings.highlight.link('LspReferenceWrite', 'CursorColumn')
    registry.group(function ()
      registry.auto('CursorHold', vim.lsp.buf.document_highlight, '<buffer>')
      registry.auto('CursorMoved', vim.lsp.buf.clear_references, '<buffer>')
    end)
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

    for _, fn in ipairs(setups) do
      fn()
    end
    setups = {}
    has_been_setup = true
  else
    -- generate a chainable object for setting up LSP
    return generate_lsp_setup(name)
  end
end

M.on_setup = function (fn)
  if has_been_setup then
    fn()
    return
  end

  table.insert(setups, fn)
end

return M
