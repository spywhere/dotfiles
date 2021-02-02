local M = {}

local _lazy = {}

M.is_installed = function ()
  return fn.filereadable(vim_plug_path) ~= 0
end

local install_plugins = function (registry)
  vim.cmd('PlugInstall --sync | q')
  vim.schedule_wrap(registry.reload)
end

local install_missing_plugins = function (registry)
  local is_plugin_missing = function (plugin)
    local stat = luv.fs_stat(plugin.dir)
    if not stat or stat.type ~= 'directory' then
      return true
    end
    return false
  end

  local plugins = vim.tbl_values(vim.g.plugs)
  local missing_plugins = vim.tbl_filter(is_plugin_missing, plugins)
  if vim.tbl_count(missing_plugins) == 0 then
    return
  end

  vim.cmd('PlugInstall --sync | q')
end

M.install = function (registry)
  vim.cmd(
    'silent !curl -fLo ' .. vim_plug_path .. ' --create-dirs ' .. vim_plug_url
  )

  registry.auto('VimEnter', install_plugins)
  registry.require_reload()
end

M.pre = function ()
  fn['plug#begin'](plugin_home)
end

M.load = function (plugin)
  local options = plugin.options or {}

  if options.lazy then
    options.on = {}
    table.insert(_lazy, options.lazy)
    options.lazy = nil
  end

  options[true] = vim.types.dictionary
  fn['plug#'](plugin.name, options)
end

local lazy_load = function ()
  for _, plugin in ipairs(_lazy) do
    fn['plug#load'](plugin)
  end
  _lazy = nil
end

M.post = function (registry)
  fn['plug#end']()
  -- Automatically install missing plugins on startup
  registry.auto('VimEnter', install_missing_plugins)
  if vim.tbl_count(_lazy) > 0 then
    vim.defer_fn(lazy_load, 1000)
  end
end

return M
