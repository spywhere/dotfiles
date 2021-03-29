local registry = require('lib/registry')

registry.install('itchyny/lightline.vim')
registry.post(function ()
  local components = {
    Mode = function ()
      return fn['lightline#mode']()
    end,
    Branch = function ()
      return fn['gitbranch#name']()
    end,
    Readonly = function ()
      if vim.bo.readonly then
        return '+'
      else
        return ''
      end
    end,
    Modified = function ()
      if vim.bo.modified then
        return '+'
      else
        return ''
      end
    end,
    RelativePath = function ()
      local winwidth = fn.winwidth(0)
      function fallback_name(winwidth, list)
        local list_count = vim.tbl_count(list)

        if list_count < 1 then
          return ''
        end
        local name = list[1]()

        if list_count == 1 then
          if name == '' then
            return '[no name]'
          else
            return name
          end
        end

        if winwidth < 60 + name:len() then
          table.remove(list, 1)
          return fallback_name(winwidth, list)
        end

        return name
      end

      return fallback_name(fn.winwidth(0), {
        function () return fn.expand('%:f') end,
        function () return fn.pathshorten(fn.expand('%:f')) end,
        function () return fn.expand('%:t') end
      })
    end,
    LineInfo = function ()
      return fn.line('.') .. ':' .. fn.col('.')
    end,
    Percent = function ()
      return math.floor(fn.line('.') * 100 / fn.line('$')) .. '%'
    end,
    FileFormat = function ()
      return vim.bo.fileformat
    end,
    FileEncoding = function ()
      return vim.bo.fileencoding
    end,
    FileType = function ()
      return vim.bo.filetype
    end
  }

  local component = function (name)
    local filetypes = {
      nvimtree = {
        relativepath = 'Explorer',
        ['*'] = ''
      },
      startify = {
        relativepath = '',
        percent = '',
        fileformat = '',
        fileencoding = '',
        lineinfo = ''
      }
    }

    return function ()
      local filetype_map = filetypes[string.lower(vim.bo.filetype)] or filetypes['*']
      if not filetype_map then
        return components[name]()
      end

      return filetype_map[string.lower(name)] or filetype_map['*'] or components[name]()
    end
  end

  for name, func in pairs(components) do
    registry.fn(
      { name = 'Lightline' .. name },
      component(name)
    )
  end

  local lightline = {
    colorscheme = 'nord',
    tabline = {
      left = {
        { 'buffers' }
      },
      right = {
        {}
      }
    },
    component_raw = {
      buffers = 1
    },
    component_expand = {
      linter_hints = 'lightline#lsp#hints',
      linter_infos = 'lightline#lsp#infos',
      linter_warnings = 'lightline#lsp#warnings',
      linter_errors = 'lightline#lsp#errors',
      linter_ok = 'lightline#lsp#ok',
      buffers = 'lightline#bufferline#buffers'
    },
    component_type = {
      linter_hints = 'right',
      linter_infos = 'right',
      linter_warnings = 'warning',
      linter_errors = 'error',
      linter_ok = 'tabsel',
      buffers = 'tabsel'
    },
    component_function = {
      obsession = 'ObsessionStatus',
      gitbranch = 'LightlineBranch',
      mode = 'LightlineMode',
      readonly = 'LightlineReadonly',
      modified = 'LightlineModified',
      relativepath = 'LightlineRelativePath',
      lineinfo = 'LightlineLineInfo',
      percent = 'LightlinePercent',
      fileformat = 'LightlineFileFormat',
      fileencoding = 'LightlineFileEncoding',
      filetype = 'LightlineFileType'
    },
    inactive = {
      left = {
        {},
        { 'relativepath' }
      },
      right = {
        { 'lineinfo' },
        { 'percent' },
        {
          'filetype'
        },
      }
    },
    active = {
      left = {
        { 'mode', 'paste' },
        { 'gitbranch', 'readonly', 'relativepath', 'modified' }
      },
      right = {
        {
          'linter_ok',
          'linter_errors',
          'linter_warnings',
          'linter_infos',
          'linter_hints'
        },
        { 'lineinfo' },
        { 'percent' },
        {
          'fileformat',
          'fileencoding',
          'filetype'
        },
        { 'obsession' }
      }
    }
  }

  vim.g.lightline = lightline
end)

registry.install('mengelbrecht/lightline-bufferline')
registry.post(function ()
  vim.g['lightline#bufferline#enable_devicons'] = 1
  vim.g['lightline#bufferline#min_buffer_count'] = 2
  vim.g['lightline#bufferline#clickable'] = 1
end)

registry.install('spywhere/lightline-lsp')
registry.install('mhinz/vim-startify')
registry.post(function ()
  vim.g.startify_files_number = 20
  vim.g.startify_fortune_use_unicode = 1
  vim.g.startify_enable_special = 0
  vim.g.startify_custom_header = 'startify#center(startify#fortune#cowsay())'
  vim.g.startify_change_to_dir = 0

  vim.g.startify_lists = {
    { type = 'dir',   header = { '   MRU ' .. fn.getcwd() } },
    { type = 'files', header = { '   MRU' } }
  }

  local get_icon = function (path)
    local devicons = require('nvim-web-devicons')
    local filename = fn.fnamemodify(path, ':t')
    local extension = fn.fnamemodify(path, ':e')
    local icon = devicons.get_icon(filename, extension, { default = true })
    if icon then
      return icon.." "
    else
      return ""
    end
  end

  registry.fn(
    { name = 'StartifyEntryFormat' },
    function ()
      local call = {
        registry.call_for_fn(get_icon, { 'absolute_path' }),
        '" "',
        'entry_path'
      }
      return table.concat(call, ' . ')
    end
  )
end)
