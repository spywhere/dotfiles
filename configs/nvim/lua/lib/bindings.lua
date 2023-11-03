local M = {}

M.set = function (option, valueOrOperator, value)
  local operator = '='
  if valueOrOperator == nil then
    value = not vim.startswith(option, 'no')
    option = value and option or string.sub(option, 3)
  elseif value == nil then
    value = valueOrOperator
  else
    operator = valueOrOperator
  end

  if operator == '=' then
    vim.o[option] = value
  elseif operator == '+=' then
    vim.opt[option]:append(value)
  elseif operator == '^=' then
    vim.opt[option]:prepend(value)
  elseif operator == '-=' then
    vim.opt[option]:remove(value)
  end
end

M.cmd = function (name, command)
  assert(command[1], 'command \'' .. name ..'\' definition is required')
  assert(
    type(command[1]) == 'function',
    'command \'' .. name .. '\' expect function as first argument'
  )
  local attributes = {}
  for k, v in pairs(command) do
    if type(k) == 'string' then
      attributes[k] = v
    end
  end

  api.nvim_create_user_command(name, command[1], attributes)
end

M.sign = {
  define = fn.sign_define
}
M.highlight = {
  define = api.nvim_set_hl
}

local build_lua_map_ops = function (tbl)
  local sep = ' '
  if tbl.import then
    sep = '.'
  end

  local ops = table.concat(tbl, sep)

  if tbl.import then
    return '<cmd>lua require(\'' .. tbl.import .. '\').' .. ops .. '<cr>'
  else
    return '<cmd>lua ' .. ops .. '<cr>'
  end
end

local map = function (mapper)
  local defaultOptions = { noremap = true, silent = true }

  local keymap = function (modes)
    return function (key, _ops, _options)
      local ops = _ops or ''
      local options = vim.tbl_extend(
        'force',
        defaultOptions,
        _options or {}
      )

      if type(ops) == 'function' then
        options.callback = ops
        ops = ''
      end

      if type(ops) == 'table' then
        ops = build_lua_map_ops(ops)
      end

      if not modes then
        mapper('', key, ops, options)
        return
      end

      for _, mode in ipairs(modes) do
        mapper(mode, key, ops, options)
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
    nv = keymap {'n', 'v'},
    nt = keymap {'n', 't'}
  }
end

local buffer_set_keymap = function (mode, lhs, rhs, opts)
  api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
end

M.map = map(api.nvim_set_keymap)
M.map.buffer = map(buffer_set_keymap)

return M
