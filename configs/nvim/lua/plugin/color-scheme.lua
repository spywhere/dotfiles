local registry = require('lib.registry')
local colors = require('common.colors')

registry.install {
  'rmehri01/onenord.nvim',
  config = function ()
    local onenord = require('onenord.colors').load()

    local custom_highlights = {
      NvimTreeVertSplit = { fg = onenord.selection, bg = onenord.none },
      LspReferenceText = { bg = onenord.highlight, style = onenord.none },
      LspReferenceRead = { bg = onenord.highlight, style = onenord.none },
      LspReferenceWrite = { bg = onenord.highlight, style = onenord.none },
      TelescopeSelection = { bg = onenord.highlight },
      IndentBlanklineContextChar = { fg = onenord.blue },
      NormalFloat = { bg = onenord.bg },
      NavicText = {
        bg = colors.resolve_color('black').gui,
        fg = onenord.fg
      },
      NavicSeparator = {
        bg = colors.resolve_color('black').gui,
        fg = onenord.cyan
      },
      NvimTreeNormal = {
        bg = colors.darkgray.gui,
        fg = onenord.white
      }
    }

    local modes = {
      NormalMode = { fg='cyan', bg='black' },
      InsertMode = { fg='white', bg='black' },
      VisualMode = { fg='green', bg='black' },
      CommandMode = { fg='cyan', bg='black' },
      TerminalMode = { fg='black', bg='white' },
      SelectMode = { fg='brightcyan', bg='black' },
      ReplaceMode = { fg='yellow', bg='black' }
    }

    for key, color in pairs(modes) do
      custom_highlights[key] = colors.group(color.fg, color.bg)
      custom_highlights[key].style = 'reverse'
      custom_highlights[key .. 'Invert'] = colors.group(color.fg, color.bg)
    end

    local navic_highlights = {
      File = onenord.blue,
      Module = onenord.blue,
      Namespace = onenord.yellow,
      Package = onenord.orange,
      Class = onenord.yellow,
      Method = onenord.purple,
      Property = onenord.blue,
      Field = onenord.blue,
      Constructor = onenord.yellow,
      Enum = onenord.yellow,
      Interface = onenord.yellow,
      Function = onenord.purple,
      Variable = onenord.blue,
      Constant = onenord.orange,
      String = onenord.green,
      Number = onenord.orange,
      Boolean = onenord.orange,
      Array = onenord.yellow,
      Object = onenord.orange,
      Key = onenord.purple,
      Null = onenord.red,
      EnumMember = onenord.cyan,
      Struct = onenord.yellow,
      Event = onenord.purple,
      Operator = onenord.purple,
      TypeParameter = onenord.yellow
    }

    for key, color in pairs(navic_highlights) do
      custom_highlights['NavicIcons' .. key] = {
        bg = colors.resolve_color('black').gui,
        fg = color
      }
    end

    require('onenord').setup {
      custom_highlights = custom_highlights,
      custom_colors = {
        bg = colors.darkgray.gui,
        diff_change = onenord.yellow,
        status = colors.resolve_color('black').gui
      }
    }
  end
}
