-- neovim api bindings
local _bindings = 'lib/bindings'
local std = {}
std.count = function ()
  local i = 0
  return function ()
    i = i + 1
    return i
  end
end

local M = {}

local increment = std.count()

local _callbacks = {}

M._cmd = function (index, args, ...)
  local modifiers = {...}
  modifiers.args = args
  return function (...)
    _callbacks[index](modifiers, ...)
  end
end

M._call = function (index, ...)
  _callbacks[index](M, ...)
end

M.set = function (option, valueOrOperator, value)
  local expression = function ()
    if not valueOrOperator then
      return 'set ' .. option
    elseif not value then
      return 'set ' .. option .. '=' .. valueOrOperator
    else
      return 'set ' .. option .. valueOrOperator .. value
    end
  end

  api.nvim_command(expression())
end

M.cmd = function (name, command)
  assert(command[1], 'command \'' .. name ..'\' definition is required')
  assert(
    type(command[1]) == 'function',
    'command \'' .. name .. '\' expect function as first argument'
  )
  local index = increment()
  _callbacks[index] = command[1]
  local definition = { 'command!' }
  local command_args = { index, '<q-args>' }
  for k, v in pairs(command) do
    if type(k) == 'string' and type(v) == 'boolean' and v then
      table.insert(definition, '-' .. k)
      local escape_arg = ({
        bang = '\'<bang>\'',
        count = '\'<count>\''
      })[k]
      if escape_arg then
        table.insert(command_args, escape_arg)
      end
    elseif type(k) == 'number' and type(v) == 'string' and v:match('^%-') then
      table.insert(definition, v)
    end
  end
  table.insert(definition, name)

  local expression = {
    'lua require(\'' .. _bindings ..'\')',
    '_cmd('.. table.concat(command_args, ',') .. ')(<f-args>)'
  }

  table.insert(definition, table.concat(expression, '.'))

  api.nvim_command(table.concat(definition, ' '))
end

local define_sign = function (name, arguments)
  local expression = { 'sign', 'define', name }
  for k, v in pairs(arguments) do
    if type(k) == 'string' and type(v) == 'string' then
      table.insert(expression, string.format('%s=%s', k, v))
    elseif type(k) == 'number' and type(v) == 'string' then
      table.insert(expression, v)
    end
  end
  api.nvim_command(table.concat(expression, ' '))
end

local define_highlight = function (name, colors)
  local expression = { 'highlight', name }
  if type(colors) == 'string' then
    table.insert(expression, colors)
  elseif type(colors) == 'table' then
    for k, v in pairs(colors) do
      if type(k) == 'string' and type(v) == 'string' then
        table.insert(expression, string.format('%s=%s', k, v))
      elseif type(k) == 'number' and type(v) == 'string' then
        table.insert(expression, v)
      end
    end
  end
  api.nvim_command(table.concat(expression, ' '))
end

local link_highlight = function (name, target, is_default)
  local expression = { 'highlight' }
  if is_default ~= false then
    table.insert(expression, 'default')
  end
  table.insert(expression, 'link')
  table.insert(expression, name)
  table.insert(expression, target or 'NONE')
  api.nvim_command(table.concat(expression, ' '))
end

M.sign = {
  define = define_sign
}
M.highlight = {
  define = define_highlight,
  link = link_highlight
}

local build_lua_map_ops = function (tbl)
  local sep = ' '
  if tbl.import then
    sep = '.'
  end

  local ops = table.concat(tbl, sep)

  if tbl.import then
    return '<cmd>lua require(\'' .. tbl.import .. '\')' .. ops
  else
    return '<cmd>lua ' .. ops
  end
end

local map = function (mapper)
  local defaultOptions = { noremap = true, silent = true }

  local keymap = function (modes)
    return function (key, ops, options)
      local ops = ops or ''
      local options = vim.tbl_extend(
        'force',
        defaultOptions,
        options or {}
      )

      if type(ops) == 'function' then
        local index = increment()
        _callbacks[index] = ops
        ops = {
          import = _bindings,
          '_call(' .. index .. ')'
        }
      end

      if type(ops) == 'table' then
        ops = '<cmd>lua ' .. build_lua_map_ops(ops)
      end

      if not modes then
        api.nvim_set_keymap('', key, ops, options)
        return
      end

      for _, mode in ipairs(modes) do
        api.nvim_set_keymap(mode, key, ops, options)
      end
    end
  end

  return {
    mode = keymap,
    all = keymap (),
    normal = keymap {'n'},
    command = keymap {'c'},
    visual = keymap {'v'},
    insert = keymap {'i'},
    replace = keymap {'r'},
    operator = keymap {'o'},
    terminal = keymap {'t'},
    ni = keymap {'n', 'i'},
    nv = keymap {'n', 'v'}
  }
end

local buffer_set_keymap = function (mode, lhs, rhs, opts)
  api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
end

M.map = map(api.nvim_set_keymap)
M.map.buffer = map(buffer_set_keymap)

M.executable = function (executable)
  return fn.executable(executable) == 1
end

return M
