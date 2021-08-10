local M = {}

local _lazy = {}
local _plugins = {}

M.is_installed = function ()
  return fn.filereadable(vim_plug_path) ~= 0
end

local install_plugins = function (registry)
  vim.cmd('PlugInstall --sync | q')
  vim.schedule_wrap(registry.reload)
end

local install_missing_plugins = function ()
  local is_plugin_missing = function (plugin)
    local stat = luv.fs_stat(plugin.dir)
    if not stat or stat.type ~= 'directory' then
      return true
    end
    return false
  end

  local plugins = vim.tbl_values(vim.g.plugs)
  local missing_plugins = vim.tbl_filter(is_plugin_missing, plugins)
  if not next(missing_plugins) then
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

local is_plugin_installed = function (name)
  if not vim.g.plugs or vim.g.plugs[name] == nil then
    return false
  end
  return fn.isdirectory(vim.g.plugs[name].dir) == 1
end

local is_plugin_loaded = function (name)
  if not vim.g.plugs or vim.g.plugs[name] == nil then
    return false
  end
  local plugin_path = vim.g.plugs[name].dir
  plugin_path = string.gsub(plugin_path, '[/\\]*$', '')
  return fn.stridx(vim.o.rtp, plugin_path) >= 0
end

local perform_post = function (plugin, post_fn, defer_fn, defer_first_fn)
  local post = post_fn or function (fn) fn() end
  local defer = defer_fn or function (fn) vim.defer_fn(fn, 10) end
  local defer_first = defer_first_fn or function (fn) vim.defer_fn(fn, 0) end

  if not is_plugin_installed(plugin.identifier) then
    return
  end

  if plugin.config then
    post(
      function ()
        plugin.config({
          installed = function ()
            return is_plugin_installed(plugin.identifier)
          end,
          loaded = function ()
            return is_plugin_loaded(plugin.identifier)
          end
        })
      end
    )
  end

  if plugin.defer then
    defer(plugin.defer)
  end

  if plugin.defer_first then
    (defer_first or defer)(plugin.defer_first)
  end
end

M.load = function (plugin, registry)
  plugin.identifier = fn.fnamemodify(plugin.name, ':t:s?\\.git$??')

  local options = plugin.options or {}

  if plugin.lazy or options.lazy then
    options.on = {}
    table.insert(_lazy, plugin)
    options.lazy = nil
  else
    table.insert(_plugins, plugin)
  end

  if type(plugin.post_install) == 'function' then
    local original_do = options['do']
    local has_prefix = function (string, prefix)
      return string.find(string, prefix, 1, true) == 1
    end

    options['do'] = vim.funcref(registry.fn(
      {
        'info'
      },
      function (info)
        -- post install
        if info.status == 'installed' then
          vim.defer_fn(function () perform_post(plugin) end, 0)
          if plugin.post_install then
            vim.defer_fn(plugin.post_install, 100)
          end
        end

        -- perform original action
        if type(original_do) == 'userdata' or type(original_do) == 'function' then
          original_do(info)
        elseif type(original_do) == 'string' then
          assert(
            has_prefix(original_do, ':'),
            'passing "do" as command line is not supported here'
          )
          vim.cmd(string.sub(original_do, 2))
        end
      end)
    )
  end

  options[true] = vim.types.dictionary
  fn['plug#'](plugin.name, options)
end

local lazy_load = function ()
  local delay = 0
  for _, plugin in ipairs(_lazy) do
    vim.defer_fn(function ()
      fn['plug#load'](plugin.identifier)
      vim.defer_fn(
        function ()
          perform_post(plugin)
        end,
        delay + 100
      )
    end, delay)
    delay = delay + 100
  end
  _lazy = nil
end

M.post = function (registry)
  fn['plug#end']()

  for _, plugin in ipairs(_plugins) do
    perform_post(plugin, registry.post, registry.defer, registry.defer_first)
  end

  -- Automatically install missing plugins on startup
  registry.auto('VimEnter', install_missing_plugins)
  if next(_lazy) then
    vim.defer_fn(function () lazy_load() end, 1000)
  end
end

return M
