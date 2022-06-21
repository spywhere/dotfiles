-- setup registry
local pm = require('lib.plugin-manager')
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

_fn = {}
local M = {}

local _group = nil
local _pre = {}
local _post = {}
local _defers = {}
local _experiments = {}
local increment = std.count()

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
  local arguments = table.concat(std.wrap(args) or {}, ',')
  table.insert(call, '_fn._' .. index .. '(' .. arguments .. ')')
  return table.concat(call, '.')
end

M.fn = function (fn_signature, fn_ref)
  local func = fn_ref
  local signature = fn_signature or {}
  if type(signature) == 'function' then
    func = signature
    signature = {}
  end
  local name = signature.name or string.format(
    '_lua_%s',
    increment()
  )
  assert(type(name) == 'string', 'function name must be a string')
  assert(
    func,
    'callback function is required for function \'' .. name .. '\''
  )
  assert(
    type(func) == 'function',
    'callback function must be a function for function \'' .. name .. '\''
  )

  local params = {}
  local args = {}
  for k, v in pairs(signature) do
    if type(k) == 'number' and type(v) == 'string' then
      table.insert(params, v)
      table.insert(args, 'a:' .. v)
    end
  end
  local definition = {
    'function! ' .. name .. '(' .. table.concat(params, ',') ..')',
    'return ' .. M.call_for_fn(func, args),
    'endfunction'
  }
  api.nvim_exec(table.concat(definition, '\n'), false)
  return name
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

M.experiment = function (name, options)
  if options == nil then
    local experiment = _experiments[name]
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
