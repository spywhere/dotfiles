local registry = require('lib.registry')

registry.install {
  'rmehri01/onenord.nvim',
  config = function ()
    local colors = {
      darkgray = '#1c1c1c',
      black = '#3b4252'
    }

    local onenord = require('onenord.colors').load()

    local custom_highlights = {
      NvimTreeVertSplit = { fg = onenord.selection, bg = onenord.none },
      LspReferenceText = { bg = onenord.highlight, style = onenord.none },
      LspReferenceRead = { bg = onenord.highlight, style = onenord.none },
      LspReferenceWrite = { bg = onenord.highlight, style = onenord.none },
      TelescopeSelection = { bg = onenord.highlight },
      IndentBlanklineContextChar = { fg = onenord.blue },
      NormalFloat = { bg = onenord.highlight },
      NavicText = { bg = colors.black, fg = onenord.fg },
      NavicSeparator = { bg = colors.black, fg = onenord.cyan }
    }

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
        bg = colors.black,
        fg = color
      }
    end

    require('onenord').setup {
      custom_highlights = custom_highlights,
      custom_colors = {
        active = colors.darkgray,
        bg = colors.darkgray,
        diff_change = onenord.yellow,
        status = colors.black
      }
    }
  end
}
