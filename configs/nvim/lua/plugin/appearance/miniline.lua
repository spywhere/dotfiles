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

[[-]] {
  hl = colors.group('white', 'brightblack'),
  visible = {
    winbar = false,
    ['*'] = true
  }
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
    active = function ()
      local mod = prequire('now-playing')
      return mod and mod.is_running()
    end
  },
  fn = function ()
    local winwidth = vim.o.laststatus == 3 and math.max(vim.o.columns, fn.winwidth(0)) or fn.winwidth(0)
    local text = string.format(
      ' %s ',
      require('now-playing').format(function (format)
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

    require('now-playing').take_over()

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
        local all_wins = api.nvim_list_wins()
        local wins = {}
        local count = 0

        for _, wid in ipairs(all_wins) do
          local win_cfg = api.nvim_win_get_config(wid)
          local bufid = api.nvim_win_get_buf(wid)
          local ft = api.nvim_buf_get_option(bufid, 'filetype')
          local skip = (
            ft == 'NvimTree' or ft == 'alpha' or ft == 'vim-plug' or
            ft == 'qf'
          )

          wins[wid] = (
            win_cfg.relative == '' and not win_cfg.external and not skip
          )
          if wins[wid] then
            count = count + 1
          end
        end

        for _, wid in ipairs(all_wins) do
          if wins[wid] and count > 1 then
            api.nvim_win_set_option(wid, 'winbar', stl.compile('winbar'))
          else
            api.nvim_win_set_option(wid, 'winbar', '')
          end
        end
      end, 10)
    end)
  end

  highlight_mode(stl.define_highlight, mode_map.n.color)
end
registry.defer(setup)
