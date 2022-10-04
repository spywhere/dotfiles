local registry = require('lib.registry')
local i = require('lib.iterator')
local bindings = require('lib.bindings')

local function highlighter(nsid, namespace)
  return function (name, highlight)
    if fn.has('nvim-0.8') == 1 then
      api.nvim_set_hl_ns_fast(nsid)
    else
      api.nvim__set_hl_ns(nsid)
    end
    bindings.highlight.define(nsid, namespace .. name, highlight)
  end
end

local function create_highlight(M, name, highlight)
  if type(name) == 'table' then
    return create_highlight(M, name.name, name.hl)
  end

  if not highlight then
    return ''
  end

  highlighter(M.ns, M.ns_name)(name, {})
  if type(highlight) == 'table' then
    highlighter(M.ns, M.ns_name)(name, highlight)
  elseif type(highlight) == 'function' then
    local highlight_map = highlight(name)
    if highlight_map then
      highlighter(M.ns, M.ns_name)(name, highlight_map)
    end
  end

  return string.format('%%#%s%s#', M.ns_name, name)
end

local function filter_state(kind)
  return function (component)
    if not component.visible then
      return true
    end

    local visible = component.visible[kind]
    if visible == nil then
      visible = component.visible['*']
    end
    return visible
  end
end

local function right_alignment(right, component)
  return right or component.name == '-'
end

local function extract_visible(component, kind)
  local visible = component.visible or {}
  return visible[kind] or visible['*']
end

local function expand_basic_component(component, kind, right, sep)
  local comp = {
    name = component.name,
    hl = component,
    value = component.str or component.fn,
    raw = component.raw,
    visible = extract_visible(component, kind)
  }

  if sep and sep ~= '' then
    if right then
      comp.after = sep
    else
      comp.before = sep
    end
  end

  return comp
end

local function expand_component(kind)
  return function (right, component)
    if component.name == '-' then
      return {
        {
          cache_name = 'Spacer',
          raw = true,
          value = '%<%=',
          hl = {
            name = '_Spacer_',
            hl = component.hl
          }
        }
      }
    end

    if component.str or component.fn then
      return {
        expand_basic_component(component, kind, right)
      }
    end

    local parts = {
      {
        allow_empty = true,
        name = component.name,
        cache_name = '_' .. component.name,
        value = component.before or ' ',
        hl = {
          name = '_' .. component.name,
          hl = component.hl
        },
        visible = extract_visible(component, kind)
      }, {
        allow_empty = true,
        name = component.name,
        hl = {
          name = component.name,
          hl = component.hl
        },
        visible = extract_visible(component, kind)
      }
    }

    vim.list_extend(
      parts,
      i
        .lazy()
        .reverse(right)
        .ordered(true)
        .map(
          function (c, index)
            c.name = string.format('%s%s', component.name, index)
            local sep
            if index ~= 1 then
              sep = component.sep or ' '
            end
            return expand_basic_component(c, kind, right, sep)
          end,
          function (c)
            if c.hl then
              c.hl.name = c.name
            end
            return c
          end
        )
        .get(component)
    )

    table.insert(parts, {
      allow_empty = true,
      name = component.name,
      cache_name = component.name .. '_',
      value = component.after or ' ',
      hl = {
        name = component.name .. '_',
        hl = component.hl
      },
      visible = extract_visible(component, kind)
    })

    return parts
  end
end

local function filter_empty(t)
  return
    t.allow_empty or
    (type(t.value) == 'function') or
    (type(t.value) == 'string' and t.value ~= '')
end

local function is_visible(t, ctx)
  if type(t.visible) == 'function' then
    return t.visible({
      value = t.value,
      kind = ctx.kind
    })
  end
  return t.visible ~= false
end

local function get_filetype_activation(component, fts)
  local filetype_map = (
    fts[string.lower(vim.bo.filetype)] or
    fts['*'] or
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
end

local function render_component(component, context, fts)
  return function ()
    local value = component.value

    if type(value) == 'function' then
      value = value(context)
    end

    if not value or value == '' then
      return value
    end

    local filetype_activation = get_filetype_activation(component, fts)
    if not is_visible(component, context) or filetype_activation then
      return filetype_activation or ''
    end

    local output = string.format(
      '%s%s%s',
      component.before or '',
      value,
      component.after or ''
    )

    if string.find(output, ' ') == 1 and #output ~= 1 then
      return ' ' .. output
    end

    return output
  end
end

local function component_renderer(M, kind)
  -- produce styling and render function to vim
  return function (component)
    local parts = {}
    local context = {
      kind = kind,
      define_highlight = highlighter(M.ns, M.ns_name)
    }

    if component.hl then
      table.insert(parts, create_highlight(M, component.hl))
    end

    local value = component.value

    if type(value) == 'function' then
      value = value(context)
    end

    if value and value ~= '' then
      if component.raw then
        table.insert(parts, value)
      else
        local cache_name = component.cache_name or component.name
        local component_call = M.component_cache[cache_name]
        if not component_call then
          component_call = string.format(
            '%%{%s}',
            registry.call_for_fn(render_component(component, context, M.fts))
          )
          M.component_cache[cache_name] = component_call
        end
        table.insert(parts, component_call)
      end
    end

    return table.concat(parts, '')
  end
end

local function compilation_pipeline(kind)
  return i.lazy()
    .filter(filter_state(kind))
    .context(right_alignment)
    .map(expand_component(kind))
    .pipe
end

local function render_pipeline(M, kind)
  return i.lazy()
    .filter(filter_empty)
    .map(component_renderer(M, kind))
    .get
end

local function compile(M, kind)
  return table.concat(
    i
      .lazy(M.components)
      .map(
        compilation_pipeline(kind),
        render_pipeline(M, kind),
        function (c) return table.concat(c, '') end
      )
      .get(),
      ''
  )
end

return function (name, components)
  local M = {
    line_cache = {},
    call_cache = {},
    component_cache = {},
    ns_name = name,
    ns = api.nvim_create_namespace(name),
    components = components
  }

  M.filetypes = function (filetypes)
    M.fts = filetypes
  end
  M.compile = function (kind, cache)
    if kind == nil then
      local winid = vim.g.statusline_winid
      local cur_winid = api.nvim_get_current_win()

      return M.compile(winid == cur_winid and "active" or "inactive")
    end

    if cache ~= false and M.line_cache[kind] then
      return M.line_cache[kind]
    end

    local line = compile(M, kind)
    M.line_cache[kind] = line
    return line
  end
  M.render = function (kind, cache)
    if M.call_cache[kind or '*'] then
      return M.call_cache[kind or '*']
    end

    local line = string.format('%%!%s', registry.call_for_fn(function ()
      return M.compile(kind, cache)
    end))
    M.call_cache[kind or '*'] = line
    return line
  end
  M.define_highlight = highlighter(M.ns, M.ns_name)

  return M
end
