local registry = require('lib.registry')
local statusline = require('lib.miniline')
local colors = require('common.colors')
local i = require('lib.iterator')

local filetypes = {
  nvimtree = {
    ['*'] = false,
    mode = fn.has('nvim-0.7') == 1,
    mode1 = fn.has('nvim-0.7') == 1,
    mode2 = fn.has('nvim-0.7') == 1,
    music = true,
    path = true,
    path1 = 'Explorer',
    clock = true,
    clock1 = true
  },
  alpha = {
    ['*'] = false,
    mode = true,
    mode1 = true,
    mode2 = true,
    music = true,
    fileinfo = true,
    fileinfo1 = true,
    fileinfo4 = true,
    clock = true,
    clock1 = true
  }
}

local mode_map = {
  n = { alias='NOM', color='cyan' },
  i = { alias='INS', color='white' },
  v = { alias='VIS', color='green' },
  V = { alias='V-L', color='green' },
  [''] = { alias='V-B', color='green' },
  c = { alias='CMD', color='cyan' },
  t = { alias='TRM', color='white' },
  s = { alias='SEL', color='brightcyan' },
  S = { alias='S-L', color='brightcyan' },
  [''] = { alias='S-B', color='brightcyan' },
  R = { alias='REP', color='yellow' }
}

local function highlight_mode(highlighter, color)
  highlighter('_Mode', colors.group(color, 'brightblack'))
  highlighter('Mode_', colors.group(color, 'black'))
  highlighter('Mode', colors.group('black', color))
end

local function is_lsp_attached()
  return next(vim.lsp.buf_get_clients(0))
end

local function get_lsp_diagnostic_count(prefix, diagnostic_type)
  return function()
    if not is_lsp_attached() then
      return ''
    end

    local active_clients = vim.lsp.get_active_clients()
    if vim.tbl_isempty(active_clients) then
      return ''
    end

    local count = vim.tbl_count(vim.diagnostic.get(
      api.nvim_get_current_buf(),
      {
        severity = diagnostic_type
      }
    ))

    if count ~= 0 then
      return (prefix or '') .. count .. ' '
    end

    return ''
  end
end

local function get_lsp_ok(text)
  return function ()
    if not is_lsp_attached() then
      return ''
    end

    local active_clients = vim.lsp.get_active_clients()
    if vim.tbl_isempty(active_clients) then
      return ''
    end

    if vim.tbl_count(vim.diagnostic.get(
      api.nvim_get_current_buf(),
      {
        severity = {
          min = vim.diagnostic.severity.HINT
        }
      }
    )) > 0 then
      return ''
    end

    return text .. ' '
  end
end

local components = i.make_table({}, function (items, value, key)
  value.name = key
  table.insert(items, value)
  return items
end)

[[Mode]] {
  before = '',
  after = '',
  sep = ' | ',
  hl = true,
  visible = {
    active = true
  },
  {
    -- Mode
    fn = function (options)
      local mode = mode_map[fn.mode()] or {
        alias=fn.mode(),
        color='red'
      }

      highlight_mode(options.define_highlight, mode.color)

      return mode.alias
    end
  },
  {
    -- Branch
    visible = {
      active = function (ctx)
        return ctx.value ~= nil and ctx.value ~= ''
      end
    },
    fn = function ()
      return fn.exists('*gitbranch#name') == 1 and fn['gitbranch#name']() or nil
    end
  }
}

[[Path]] {
  hl = colors.group('white', 'black'),
  visible = {
    active = true,
    inactive = true
  },
  {
    fn = function (options)
      local limit = options.kind == 'active' and 70 or 50

      local function split(str, sep)
        local output = {}

        for s in string.gmatch(str, '([^'..sep..']+)') do
          table.insert(output, s)
        end

        return output
      end

      local function beautify_name(name, shorten)
        if name == '' then
          return name
        end

        local output = {}
        local parts = {}

        if shorten then
          parts = split(name, '/\\')
          while #output < 7 and #parts > 0 do
            table.insert(output, 1, table.remove(parts, #parts))
          end
        end

        local is_root = string.find(name, '^[/\\[]') == 1 or string.find(name, '^%w+://')
        if not is_root then
          if shorten then
            table.insert(output, 1, '.' .. string.rep('.', #parts))
          else
            name = '.../' .. name
          end
        end

        if shorten then
          return table.concat(output, '  ')
        else
          return string.gsub(string.gsub(name, '^[/\\]', ''), '[/\\]+', '  ')
        end
      end

      local function fallback_name(winwidth, list, shorten)
        local list_count = vim.tbl_count(list)

        if list_count < 1 then
          return ''
        end
        local name = beautify_name(list[1](), shorten)

        if list_count == 1 then
          if name == '' then
            return '[no name]'
          else
            return name
          end
        end

        if winwidth < limit + name:len() then
          if shorten then
            table.remove(list, 1)
          end
          return fallback_name(winwidth, list, not shorten)
        end

        if name == '' then
          return '[no name]'
        else
          return name
        end
      end

      local winwidth = vim.o.laststatus == 3 and math.max(vim.o.columns, fn.winwidth(0)) or fn.winwidth(0)
      local value = fallback_name(winwidth, {
        function () return fn.fnamemodify(fn.expand('%'), ':.') end,
        function () return fn.pathshorten(fn.fnamemodify(fn.expand('%'), ':.')) end,
        function () return fn.expand('%:t') end
      })

      if value == '' then
        return ''
      end

      return value
    end
  }
}

[[FileStatus]] {
  hl = colors.group('white', 'black'),
  before = '[',
  after = ']',
  sep = '',
  visible = {
    winbar = false,
    ['*'] = function ()
      return vim.bo.modified or vim.bo.readonly
    end
  },
  {
    visible = {
      ['*'] = function ()
        return vim.bo.readonly
      end
    },
    str = 'RO'
  },
  {
    visible = {
      ['*'] = function ()
        return vim.bo.modified
      end
    },
    str = '+'
  }
}

[[Context]] {
  hl = colors.group('white', 'black'),
  visible = {
    winbar = true
  },
  raw = true,
  fn = function (ctx)
    local mod = prequire('nvim-navic')
    if not mod or not mod.is_available() then
      return ''
    end

    local limit = fn.winwidth(0) / 2
    local separator = '  '
    local data = mod.get_data()
    local location = {}

    if not data or #data == 0 then
      return ''
    end

    if #data > limit then
      local remain = #data - limit
      data = vim.list_slice(data, remain + 1, #data)
      table.insert(
        location,
        string.format(
          '%%#NavicText#...[%s]%%*',
          remain
        )
      )
    end

    for _, v in ipairs(data) do
      local name = string.gsub(string.gsub(v.name, '\n.*$', ''), '%s*->$', '')

      table.insert(
        location,
        string.format(
          '%%#NavicIcons%s#%s%%*%%#NavicText#%s%%*',
          v.type, v.icon, name
        )
      )
    end

    return string.format(
      ' %s%s ',
      table.concat(location, '%#NavicSeparator#' .. separator .. '%*'),
      ctx.create_highlight('Suffix')
    )
  end
}

[[-]] {
  hl = colors.group('white', 'brightblack'),
  fn = function (ctx)
    if ctx.kind ~= 'winbar' then
      return '<'
    end
  end
}

[[FileName]] {
  visible = {
    winbar = true
  },
  str = function () return fn.expand('%:t') end
}

[[Obsession]] {
  hl = colors.group('white', 'brightblack'),
  visible = {
    active = function (ctx)
      return ctx.value ~= nil
    end
  },
  fn = function ()
    return fn.exists('*ObsessionStatus') == 1 and fn.ObsessionStatus() or nil
  end
}

[[Music]] {
  hl = colors.group('white', 'black'),
  visible = {
    active = true
  },
  fn = function ()
    local mod = prequire('now-playing')
    if not mod or not mod.is_running() then
      return ''
    end

    local winwidth = vim.o.laststatus == 3 and math.max(vim.o.columns, fn.winwidth(0)) or fn.winwidth(0)
    local text = string.format(
      ' %s ',
      mod.format(function (format)
        return format()
          .format(
            '%s ',
            format()
              .map('state', {
                playing = '▶'
              }, '')
          )
          .scrollable(
            25,
            '%s - %s',
            'artist',
            'title'
          )
          .format(
            ' [%s/%s]',
            format().duration('position'),
            format().duration('duration')
          )
      end)
    )

    if winwidth < 130 + text:len() then
      return ''
    end

    mod.take_over()

    return text
  end
}

[[FileInfo]] {
  sep = ' | ',
  hl = colors.group('white', 'brightblack'),
  visible = {
    active = true,
    inactive = true
  },
  -- FileType
  {
    visible = {
      ['*'] = function ()
        return vim.bo.filetype ~= ''
      end
    },
    fn = function ()
      return vim.bo.filetype
    end
  },
  -- FileEncoding
  {
    visible = {
      ['*'] = function ()
        return vim.bo.fileencoding ~= ''
      end,
    },
    fn = function ()
      return string.upper(vim.bo.fileencoding)
    end
  },
  -- FileFormat
  {
    fn = function ()
      local formats = {
        dos = 'CRLF',
        unix = 'LF',
        mac = 'CR'
      }
      return formats[vim.bo.fileformat] or vim.bo.fileformat
    end
  },
  -- IndentStyle
  {
    fn = function ()
      local tab_style = 'TB'
      local tab_size = vim.o.tabstop
      if vim.o.expandtab then
        tab_style = 'SP'
        tab_size = vim.o.shiftwidth
      end
      return fn.printf('%s:%d', tab_style, tab_size)
    end
  }
}

[[LineInfo]] {
  hl = colors.group('white', 'black'),
  visible = {
    active = true,
    inactive = true
  },
  -- LinePercent
  {
    fn = function ()
      return fn.printf('%3d%%', math.floor(fn.line('.') * 100 / fn.line('$')))
    end
  },
  -- LineInfo
  {
    fn = function ()
      return fn.printf('%3d:%-2d', fn.col('.'), fn.line('.'))
    end
  }
}

[[Diagnostic]] {
  before = '',
  after = '',
  sep = '',
  visible = {
    active = is_lsp_attached
  },
  -- Hint
  {
    hl = colors.group('black', 'cyan'),
    fn = get_lsp_diagnostic_count(' H: ', vim.diagnostic.severity.HINT)
  },
  -- Info
  {
    hl = colors.group('black', 'green'),
    fn = get_lsp_diagnostic_count(' I: ', vim.diagnostic.severity.INFO)
  },
  -- Warn
  {
    hl = colors.group('black', 'orange'),
    fn = get_lsp_diagnostic_count(' W: ', vim.diagnostic.severity.WARN)
  },
  -- Error
  {
    hl = colors.group('black', 'red'),
    fn = get_lsp_diagnostic_count(' E: ', vim.diagnostic.severity.ERROR)
  },
  -- OK
  {
    hl = colors.group('black', 'cyan'),
    fn = get_lsp_ok(' OK')
  }
}

local setup = function ()
  local stl = statusline('miniline', components())
  stl.filetypes(filetypes)
  vim.o.statusline = stl.render()

  if fn.has('nvim-0.8') == 1 then
    registry.auto({
      'WinEnter', 'BufWinEnter', 'BufEnter',
      'WinLeave', 'BufWinLeave', 'BufLeave',
      'WinClosed'
    }, function ()
      vim.defer_fn(function ()
        local wid = api.nvim_get_current_win()

        local win_cfg = api.nvim_win_get_config(wid)
        local bufid = api.nvim_win_get_buf(wid)
        local ft = api.nvim_buf_get_option(bufid, 'filetype')
        local skip = (
          ft == 'NvimTree' or ft == 'alpha' or ft == 'vim-plug' or
          ft == 'qf'
        )

        if
          win_cfg.relative == '' and not win_cfg.external and not skip and
          vim.wo.winbar == ''
        then
          vim.wo.winbar = stl.render('winbar', false)
        end
      end, 10)
    end)
  end

  highlight_mode(stl.define_highlight, mode_map.n.color)
end
registry.post(setup)
