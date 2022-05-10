local registry = require('lib.registry')

registry.install {
  'rmehri01/onenord.nvim',
  config = function ()
    local colors = {
      darkgray = '#1c1c1c'
    }

    local onenord = require('onenord.colors').load()

    require('onenord').setup {
      custom_highlights = {
        NvimTreeVertSplit = { fg = onenord.selection, bg = onenord.none },
        LspReferenceText = { bg = onenord.highlight, style = onenord.none },
        LspReferenceRead = { bg = onenord.highlight, style = onenord.none },
        LspReferenceWrite = { bg = onenord.highlight, style = onenord.none },
        TelescopeSelection = { bg = onenord.highlight },
        IndentBlanklineContextChar = { fg = onenord.blue }
      },
      custom_colors = {
        active = colors.darkgray,
        bg = colors.darkgray,
        diff_change = onenord.yellow
      }
    }
  end
}
