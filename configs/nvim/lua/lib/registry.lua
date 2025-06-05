-- setup registry
local pm = require('lib.plugin-manager')
local _registry = 'lib.registry'
local std = {}
std.count = function ()
  local i = 0
  return function ()
    i = i + 1
    return i
  end
end
std.wrap = function (value)
  if type(value) == 'table' then
    return value
  else
    return { value }
  end
end

local M = {}

local _fn = {}
local _group = nil
local _pre = {}
local _post = {}
local _defers = {}
local _experiments = {}
local _explist = nil
local increment = std.count()

M._invoke = function(name, ...)
  return _fn[name](...)
end

M.group = function (group_name, group_fn)
  local name = group_name
  local group = group_fn
  if group then
    assert(
      type(name) == 'string' or type(name) == 'number',
      'group name must be a string or number'
    )
    assert(type(group) == 'function', 'group must be a function')
  else
    assert(type(name) == 'function', 'group must be a function')
    group = name
    name = nil
  end
  _group = api.nvim_create_augroup(
    name or string.format('_lua_%s', increment()),
    {}
  )
  group()
  _group = nil
end

M.auto = function (_events, func, _filter, _modifiers)
  if not _group then
    M.group(
      function ()
        M.auto(_events, func, _filter, _modifiers)
      end
    )
    return
  end

  local events = std.wrap(_events)
  for event in ipairs(events) do
    assert(fn.exists('##' .. event))
  end

  local filter = std.wrap(_filter or '*')

  api.nvim_create_autocmd(events, {
    group = _group,
    pattern = filter,
    callback = func
  })
end

M.call_for_fn = function (func, args)
  local call = { 'v:lua' }
  local index = increment()
  _fn['_' .. index] = func
  local arguments = table.concat(
    vim.list_extend({ '\'_' .. index .. '\'' }, std.wrap(args) or {}),
    ','
  )
  table.insert(
    call,
    'require(\'' .. _registry ..'\')._invoke(' .. arguments .. ')'
  )
  return table.concat(call, '.')
end

local install_plugin_manager = function (callback)
  if pm.is_installed() then
    if callback then
      callback(true)
    end
    return
  end

  if callback then
    callback(pm.install())
  else
    return pm.install()
  end
end

local get_experiment_options = function (name)
  if _explist == nil and fn.filereadable(fn.expand('~/.explist')) == 1 then
    _explist = {}
    vim.tbl_map(
      function (exp)
        local experiment = vim.split(exp, '=')
        local expname, value = experiment[1], string.lower(experiment[2])
        if value == 'a' or value == 'false' or value == 'off' or value == 'no' then
          _explist[expname] = false
        elseif value == 'b' or value == 'true' or value == 'on' or value == 'yes' then
          _explist[expname] = true
        else
          _explist[expname] = value
        end
      end,
      fn.readfile(fn.expand('~/.explist'))
    )
  end

  if _explist and _explist[name] ~= nil then
    return _explist[name]
  end

  return _experiments[name]
end

M.experiment = function (name, options, start)
  local run_duration = 2592000 -- 30 days
  if options == nil then
    local experiment = get_experiment_options(name)

    local is_on = experiment
    if type(experiment) == 'table' then
      is_on = next(experiment)
    end

    return {
      on = function ()
        return is_on
      end,
      off = function ()
        return not is_on
      end,
      be = function (value)
        return function ()
          return experiment == value
        end
      end,
      not_be = function (value)
        return function ()
          return experiment ~= value
        end
      end,
      is = function (value)
        return experiment == value
      end,
      is_not = function (value)
        return experiment ~= value
      end,
      options = function ()
        return experiment
      end
    }
  end

  local now = os.time()

  if start and now - start > run_duration then
    vim.defer_fn(function ()
      vim.notify(string.format(
        'Experiment "%s" is running over 30 days, please clean up when possible',
        name
      ), vim.log.levels.WARN)
    end, 10)
  end

  _experiments[name] = options
end

M.install = pm.add

M.pre = function (callback)
  table.insert(_pre, callback)
end

local iterate_pre = function ()
  for _, func in ipairs(_pre) do
    func()
  end
  _pre = {}
end

M.post = function (callback)
  table.insert(_post, callback)
end

M.defer_first = function (callback)
  table.insert(_defers, 1, callback)
end

M.defer = function (callback)
  table.insert(_defers, callback)
end

local iterate_defer = function ()
  for _, func in ipairs(_post) do
    func()
  end
  _post = {}

  local delay = 300
  for _, func in ipairs(_defers) do
    vim.defer_fn(func, delay)
    delay = delay + 10
  end
  _defers = {}
end

M.reload = function ()
  if vim.g.init_vim_loaded ~= 1 then
    return
  end

  M.startup()
end

M.startup = function(callback)
  if callback then
    install_plugin_manager(function (installed)
      if not installed then
        return
      end
      callback()
      M.startup()
    end)
    return
  end

  iterate_pre()
  install_plugin_manager(function ()
    pm.setup()
    iterate_defer()
  end)
end

return M
