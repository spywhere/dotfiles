local registry = require('lib/registry')
local bindings = require('lib/bindings')

--[[
Refactor:
  - Build the whole status line first
    - Layout the style (as needed) and function map
  - Separate data and rendering
    - Better diagnostic styling
    - Segmented controls
  - active, inactive, filetype have to check at runtime
  - Child component must inherits parent property as well
    - when parent is hidden, child must be hidden as well
--]]

local M = {}

local _fts = {}

M.filetypes = function (filetypes)
  _fts = filetypes
end

local function define_highlight(name, highlight)
  bindings.highlight.define(M.ns_name .. name, highlight)
end

local function component_highlight(name, highlight)
  if type(name) == 'table' then
    return component_highlight(name.name, name.hl)
  end
  if not highlight then
    return ''
  end
  api.nvim_set_hl(M.ns, name, {})
  if type(highlight) == 'table' then
    define_highlight(name, highlight)
  elseif type(highlight) == 'function' then
    local highlight_map = highlight(name)
    if highlight_map then
      define_highlight(name, highlight_map)
    end
  end
  return string.format('%%#%s%s#', M.ns_name, name)
end

local function render_component(active, sep, is_right_component)
  local styled_value = function (value, component)
    if component.inactive == false and not active then
      return ''
    end

    if component.active and not component.active() then
      return ''
    end

    local filetype_map = (
      _fts[string.lower(vim.bo.filetype)] or
      _fts['*'] or
      {}
    )

    local filetype_activation = (
      filetype_map[string.lower(component.name)] or
      filetype_map['*']
    )
    if filetype_activation ~= nil then
      if not filetype_activation then
        return ''
      elseif type(filetype_activation) == 'string' then
        return filetype_activation
      end
    end

    local output = ''

    if sep and sep ~= '' and not is_right_component then
      output = sep
    end

    output = output .. value

    if sep and sep ~= '' and is_right_component then
      output = output .. sep
    end

    if string.find(output, ' ') == 1 then
      return ' ' .. output
    else
      return output
    end
  end

  local forward_iter = function (t, idx)
    idx = idx + 1
    if idx ~= #t + 1 then
      return idx, t[idx]
    end
  end
  local backward_iter = function (t, idx)
    idx = idx - 1
    if idx ~= 0 then
      return idx, t[idx]
    end
  end
  local directional_ipairs = function (t)
    if is_right_component then
      return backward_iter, t, #t + 1
    else
      return forward_iter, t, 0
    end
  end

  return function (component)
    if component.name == '-' then
      is_right_component = true
      return string.format(
        '%s%%=',
        component_highlight('_Spacer_', component.hl)
      )
    end

    local parts = {}
    for _, subpart in directional_ipairs(component) do
      subpart.name = string.format('%s%s', component.name, _)
      local part = render_component(
        active,
        next(parts) and (component.sep or ' ') or nil,
        is_right_component
      )(subpart)
      if part ~= "" then
        if is_right_component then
          table.insert(parts, 1, part)
        else
          table.insert(parts, part)
        end
      end
    end

    -- if not component.fn and component.str then
      -- component.fn = function ()
        -- if component.active == nil or component.active() then
          -- return component.str
        -- else
          -- return ''
        -- end
      -- end
    -- end

    local basic = function (str)
      return registry.call_for_fn(function ()
        return styled_value(str or ' ', component)
      end)
    end
    if component.fn then
      return string.format(
        '%s%%{%s}',
        component_highlight(component),
        registry.call_for_fn(function ()
          return styled_value(component.fn({
            active = active,
            define_highlight = define_highlight
          }), component)
        end)
      )
    elseif next(parts) then
      return string.format(
        '%s%%{%s}%s%s%s%%{%s}',
        component_highlight('_' .. component.name, component.hl),
        basic(component.before),
        component_highlight(component),
        table.concat(parts, ''),
        component_highlight(component.name .. '_', component.hl),
        basic(component.after)
      )
    elseif component.str then
      return string.format(
        '%s%%{%s}',
        component_highlight(component),
        basic(component.str)
      )
    end

    return ''
  end
end

M.compile = function (active)
  return table.concat(
    vim.tbl_values(vim.tbl_map(render_component(active), M.components)),
    ''
  )
end

return function (name, components)
  M.ns_name = name
  M.ns = api.nvim_create_namespace(name)
  M.components = components
  api.nvim__set_hl_ns(M.ns)
  return M
end
