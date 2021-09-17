local registry = require('lib/registry')
local statusline = require('lib/statusline')
local colors = require('common/colors')
local i = require('lib/iterator')

local filetypes = {
  nvimtree = {
    ['*'] = false,
    path = true,
    path1 = 'Explorer'
  },
  startify = {
    ['*'] = false,
    mode = true,
    mode1 = true,
    mode2 = true,
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

    local types = { 'Error', 'Warning', 'Info', 'Hint' }
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
  inactive = false,
  {
    -- Mode
    inactive = false,
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
    active = function ()
      return fn['gitbranch#name']() ~= ''
    end,
    inactive = false,
    fn = function ()
      return fn['gitbranch#name']()
    end
  }
}

[[Readonly]] {
  hl = colors.group('white', 'black'),
  after = '',
  {
    active = function ()
      return vim.bo.readonly
    end,
    str = '[RO]'
  }
}

[[Path]] {
  hl = colors.group('white', 'black'),
  {
    fn = function (options)
      local limit = options.active and 70 or 50

      local function beautify_name(name)
        if name == '' then
          return name
        end

        local is_root = string.find(name, '^[/\\[]') == 1 or string.find(name, '^%w+://')
        if not is_root then
          name = '.../' .. name
        end

        return string.gsub(string.gsub(name, '^[/\\]', ''), '[/\\]+', '  ')
      end

      local function fallback_name(winwidth, list)
        local list_count = vim.tbl_count(list)

        if list_count < 1 then
          return ''
        end
        local name = beautify_name(list[1]())

        if list_count == 1 then
          if name == '' then
            return '[no name]'
          else
            return name
          end
        end

        if winwidth < limit + name:len() then
          table.remove(list, 1)
          return fallback_name(winwidth, list)
        end

        if name == '' then
          return '[no name]'
        else
          return name
        end
      end

      local value = fallback_name(fn.winwidth(0), {
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

[[Modified]] {
  hl = colors.group('white', 'black'),
  active = function ()
    return vim.bo.modified
  end,
  str = '[+]'
}

[[-]] {
  hl = colors.group('white', 'brightblack'),
}

[[Obsession]] {
  hl = colors.group('white', 'brightblack'),
  inactive = false,
  fn = function ()
    return fn.ObsessionStatus()
  end
}

[[FileInfo]] {
  sep = ' | ',
  hl = colors.group('white', 'brightblack'),
  -- FileType
  {
    active = function ()
      return vim.bo.filetype ~= ''
    end,
    fn = function ()
      return vim.bo.filetype
    end
  },
  -- FileEncoding
  {
    active = function ()
      return vim.bo.fileencoding ~= ''
    end,
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
      if vim.o.expandtab then
        tab_style = 'SP'
      end
      return fn.printf('%s:%d', tab_style, vim.o.tabstop)
    end
  }
}

[[LineInfo]] {
  hl = colors.group('white', 'black'),
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
  inactive = false,
  active = is_lsp_attached,
  -- Hint
  {
    hl = colors.group('black', 'cyan'),
    inactive = false,
    active = is_lsp_attached,
    fn = get_lsp_diagnostic_count(' H: ', vim.diagnostic.severity.HINT)
  },
  -- Info
  {
    hl = colors.group('black', 'green'),
    inactive = false,
    active = is_lsp_attached,
    fn = get_lsp_diagnostic_count(' I: ', vim.diagnostic.severity.INFO)
  },
  -- Warn
  {
    hl = colors.group('black', 'orange'),
    inactive = false,
    active = is_lsp_attached,
    fn = get_lsp_diagnostic_count(' W: ', vim.diagnostic.severity.WARN)
  },
  -- Error
  {
    hl = colors.group('black', 'red'),
    inactive = false,
    active = is_lsp_attached,
    fn = get_lsp_diagnostic_count(' E: ', vim.diagnostic.severity.ERROR)
  },
  -- OK
  {
    hl = colors.group('black', 'cyan'),
    inactive = false,
    active = is_lsp_attached,
    fn = get_lsp_ok(' OK')
  }
}

[[Clock]] {
  before = '',
  after = '',
  hl = function (part)
    if part == 'Clock' then
      return colors.group('white', 'lightblue')
    else
      return colors.group('lightblue', 'black')
    end
  end,
  inactive = false,
  active = function ()
    return fn.exists('g:GuiLoaded') == 1
  end,
  -- Clock
  {
    inactive = false,
    active = function ()
      return fn.exists('g:GuiLoaded') == 1
    end,
    fn = function ()
      return os.date('%d %b %y %H:%M')
    end
  }
}

local setup = function ()
  local stl = statusline('miniline', components())
  stl.filetypes(filetypes)
  local active_line = stl.compile(true)
  local inactive_line = stl.compile(false)
  local active_events = {
    'ColorScheme', 'FileType', 'BufWinEnter', 'BufReadPost', 'BufWritePost',
    'BufEnter', 'WinEnter', 'FileChangedShellPost', 'VimResized','TermOpen'
  }
  highlight_mode(stl.define_highlight, mode_map.n.color)
  vim.wo.statusline = active_line
  registry.auto(active_events, function ()
    vim.wo.statusline = active_line
  end)
  registry.auto('WinLeave', function ()
    vim.wo.statusline = inactive_line
  end)
end
registry.defer(setup)
