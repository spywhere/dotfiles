local registry = require('lib/registry')
local bindings = require('lib/bindings')
local colors = require('common/colors')

registry.install {
  'glepnir/galaxyline.nvim',
  defer = function ()
    local components = {
      Branch = function ()
        return fn['gitbranch#name']()
      end,
      Readonly = function ()
        if vim.bo.readonly then
          return '[RO]'
        else
          return ''
        end
      end,
      Modified = function ()
        if vim.bo.modified then
          return '[+]'
        else
          return ''
        end
      end,
      RelativePath = function (options)
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

          if winwidth < options.limit + name:len() then
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
          function () return fn.expand('%:f') end,
          function () return fn.pathshorten(fn.expand('%:f')) end,
          function () return fn.expand('%:t') end
        })

        if value == '' then
          return ''
        end

        return value .. ' '
      end,
      LineInfo = function ()
        return fn.printf('%3d:%-2d', fn.col('.'), fn.line('.'))
      end,
      Percent = function ()
        return fn.printf('%3d%%', math.floor(fn.line('.') * 100 / fn.line('$')))
      end,
      FileFormat = function ()
        return vim.bo.fileformat
      end,
      FileEncoding = function ()
        return vim.bo.fileencoding
      end,
      FileType = function ()
        return vim.bo.filetype
      end,
      Clock = function ()
        if fn.exists('g:GuiLoaded') == 0 then
          return ''
        end

        return os.date('%d %b %y %H:%M')
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

      return function (options)
        local filetype_map = filetypes[string.lower(vim.bo.filetype)] or filetypes['*']
        if not filetype_map then
          return components[name](options)
        end

        return filetype_map[string.lower(name)] or filetype_map['*'] or components[name](options)
      end
    end

    local statusline = {
      bg='brightblack',
      fg='white'
    }

    local refine_section = function (palette, sections, inactive)
      local line = {}

      local section_map = function (key, section)
        local hide_on_inactive = section.inactive == false and inactive
        local hide_on_active = section.active == false and not inactive
        if hide_on_active or hide_on_inactive then
          return
        end

        local provider
        local raw_provider
        local nohighlight = true

        if type(section) == 'string' then
          provider = section
          section = {}
        elseif type(section) == 'table' then
          if components[section.component] ~= nil then
            raw_provider = component(section.component)
          else
            provider = section.provider
          end
          nohighlight = section.nohighlight or false
        end

        local transform_provider = function (provider, separator, options)
          return function ()
            local value = provider(options) or ''
            if value == '' then
              return ''
            elseif separator == nil then
              return value
            else
              return (separator.left or '') .. value .. (separator.right or '')
            end
          end
        end

        if type(provider) == 'string' then
          raw_provider = transform_provider(function () return provider end, section.separator)
        elseif raw_provider == nil then
          raw_provider = transform_provider(provider, section.separator, section.options)
        else
          raw_provider = transform_provider(raw_provider, section.separator, section.options or {})
        end

        local component = {
          provider = raw_provider,
          icon = section.icon,
          condition = section.condition
        }

        if not nohighlight then
          component.highlight = {
            colors.resolve_color(section.foreground or palette.fg).gui,
            colors.resolve_color(section.background or palette.bg).gui
          }
        end

        table.insert(line, {
          [key] = component
        })
      end

      -- loop through list
      for key, value in ipairs(sections) do
        if type(key) == 'number' then
          -- each item is an object with one key
          for name, section in pairs(value) do
            section_map(name, section)
            break
          end
        end
      end
      return line
    end

    local sections = {
      left = {
        {
          ModeLeft = {
            provider = ''
          }
        },
        {
          Mode = {
            provider = function ()
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

              local mode = mode_map[fn.mode()] or {
                alias=fn.mode(),
                color='red'
              }
              bindings.highlight.define('GalaxyModeLeft', colors.group(mode.color, 'brightblack'))
              bindings.highlight.define('GalaxyModeRight', colors.group(mode.color, 'black'))
              bindings.highlight.define('GalaxyMode', colors.group('black', mode.color))
              bindings.highlight.define('GalaxyGitBranch', colors.group('black', mode.color))

              return mode.alias
            end,
            inactive = false
          },
        },
        {
          GitBranch = {
            component = 'Branch',
            separator = {
              left = '  | '
            },
            inactive = false
          }
        },
        {
          ModeRight = {
            provider = ''
          }
        },
        {
          Spacing = {
            provider = ' ',
            background = 'black'
          }
        },
        {
          Readonly = {
            component = 'Readonly',
            separator = {
              left = ' | '
            }
          }
        },
        {
          RelativePath = {
            component = 'RelativePath',
            options = { limit = 70 },
            background = 'black',
            inactive = false
          }
        },
        {
          RelativePathInactive = {
            component = 'RelativePath',
            options = { limit = 50 },
            background = 'black',
            active = false
          }
        },
        {
          Modified = {
            component = 'Modified'
          }
        }
      },
      right = {
        {
          ObsessionStatus = {
            provider = fn.ObsessionStatus,
            separator = {
              right = ' '
            },
            inactive = false
          }
        },
        {
          FileType = {
            component = 'FileType',
            separator = {
              right = ' '
            }
          }
        },
        {
          FileEncoding = {
            component = 'FileEncoding',
            separator = {
              left = '| ',
              right = ' | '
            }
          }
        },
        {
          FileFormat = {
            component = 'FileFormat',
            separator = {
              right = ' '
            }
          }
        },
        {
          LinePercent = {
            component = 'Percent',
            background = 'black',
            separator = {
              left = '  ',
              right = ' '
            }
          }
        },
        {
          LineInfo = {
            component = 'LineInfo',
            background = 'black',
            separator = {
              left = ' ',
              right = ' '
            }
          }
        },
        {
          DiagnosticHint = {
            provider = require('galaxyline.provider_diagnostic').get_diagnostic_hint,
            icon = '  H:',
            foreground = 'black',
            background = 'cyan',
            inactive = false
          }
        },
        {
          DiagnosticInfo = {
            provider = require('galaxyline.provider_diagnostic').get_diagnostic_info,
            icon = '  I:',
            foreground = 'black',
            background= 'green',
            inactive = false
          }
        },
        {
          DiagnosticWarn = {
            provider = require('galaxyline.provider_diagnostic').get_diagnostic_warn,
            icon = '  W:',
            foreground = 'black',
            background = 'orange',
            inactive = false
          }
        },
        {
          DiagnosticError = {
            provider = require('galaxyline.provider_diagnostic').get_diagnostic_error,
            icon = '  E:',
            background = 'red',
            inactive = false
          }
        },
        {
          DiagnosticOK = {
            provider = function ()
              if vim.tbl_isempty(vim.lsp.buf_get_clients(0)) then
                return ''
              end

              local active_clients = vim.lsp.get_active_clients()
              if vim.tbl_isempty(active_clients) then
                return ''
              end

              local types = { 'Error', 'Warning', 'Info', 'Hint' }
              for _, diag_type in ipairs(types) do
                for _, client in ipairs(active_clients) do
                  if vim.lsp.diagnostic.get_count(api.nvim_get_current_buf(),diag_type,client.id) > 0 then
                    return ''
                  end
                end
              end

              return 'OK '
            end,
            icon = '  ',
            foreground = 'black',
            background = 'cyan',
            inactive = false
          }
        },
        {
          ClockSpacing = {
            provider = function ()
              if fn.exists('g:GuiLoaded') == 0 then
                return ''
              end

              return ' '
            end,
            background = 'black',
            inactive = false
          }
        },
        {
          ClockLeft = {
            provider = function ()
              if fn.exists('g:GuiLoaded') == 0 then
                return ''
              end

              return ''
            end,
            foreground = 'lightblue',
            background = 'black',
            inactive = false
          }
        },
        {
          Clock = {
            component = 'Clock',
            background = 'lightblue',
            inactive = false
          }
        },
        {
          ClockRight = {
            provider = function ()
              if fn.exists('g:GuiLoaded') == 0 then
                return ''
              end

              return ''
            end,
            foreground = 'lightblue',
            background = 'black',
            inactive = false
          }
        }
      }
    }

    local gl = require('galaxyline')
    gl.short_line_list = { '' }
    gl.section = {
      mid = {},
      short_line_left = refine_section(statusline, sections.left, true),
      short_line_right = refine_section(statusline, sections.right, true),
      left = refine_section(statusline, sections.left),
      right = refine_section(statusline, sections.right)
    }
  end
}

registry.install {
  'akinsho/nvim-bufferline.lua',
  defer = function ()
    local is_gui = fn.exists('g:GuiLoaded') == 1
    require('bufferline').setup({
      options = {
        diagnostics = false,
        always_show_bufferline = false,
        show_close_icon = false,
        show_buffer_close_icons = is_gui,
        indicator_icon = ' ',
        separator_style = { '', '' },
        offsets = {
          {
            filetype = "NvimTree",
            text = "Explorer",
            highlight = "Directory",
            text_align = "left"
          }
        }
      }
    })

    -- workaround to fix tabline from showing during start up with startify
    local hide_tabline = function ()
      local total_buffers = vim.tbl_count(fn.getbufinfo({ buflisted = 1 }))
      if total_buffers > 1 then
        return
      end

      bindings.set('showtabline', 0)
    end
    vim.defer_fn(hide_tabline, 0)
  end
}

registry.install {
  'mhinz/vim-startify',
  post_install = function ()
    vim.cmd('Startify')
    vim.defer_fn(function ()
      api.nvim_command('IndentBlanklineDisable')
    end, 100)
  end,
  config = function ()
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
  end
}
