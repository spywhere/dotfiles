local bindings = require('lib/bindings')
local registry = require('lib/registry')
local colors = require('common/colors')

local color_setup = function ()
  local base_highlights = {
    -- dark background
    Normal = colors.group(nil, 'darkgray', colors),
    -- invisible splits
    SignColumn = colors.group(nil, 'darkgray', colors),
    VertSplit = colors.group('darkgray', 'darkgray', colors)
  }

  for k, v in pairs(base_highlights) do
    bindings.highlight.define(k, v)
  end

  local highlight_definitions = {
    -- TabLine = colors.group(nil, 'brightblack'),
    -- TabLineFill = colors.group(nil, 'cyan'),
    -- TabLineSel = colors.group(nil, 'cyan'),
    -- color definition (taken from https://github.com/arcticicestudio/nord-vim/issues/235)
    TSError = colors.group('brightred'),
    TSPunctDelimiter = colors.group('blue'),
    TSPunctBracket = colors.group('blue'),
    TSPunctSpecial = colors.group('blue'),
    TSConstant = colors.group('cyan'),
    TSConstBuiltin = colors.group('dimyellow'),
    TSConstMacro = colors.group('brightcyan'),
    TSStringRegex = colors.group('green'),
    TSString = colors.group('green'),
    TSStringEscape = colors.group('brightcyan'),
    TSCharacter = colors.group('green'),
    TSNumber = colors.group('dimyellow'),
    TSBoolean = colors.group('dimyellow'),
    TSFloat = colors.group('green'),
    TSAnnotation = colors.group('yellow'),
    TSAttribute = colors.group('cyan'),
    TSNamespace = colors.group('magenta'),
    TSFuncBuiltin = colors.group('blue'),
    TSFunction = colors.group('blue'),
    TSFuncMacro = colors.group('yellow'),
    TSParameter = colors.group('brightcyan'),
    TSParameterReference = colors.group('brightcyan'),
    TSMethod = colors.group('blue'),
    TSField = colors.group('brightred'),
    TSProperty = colors.group('yellow'),
    TSConstructor = colors.group('cyan'),
    TSConditional = colors.group('magenta'),
    TSRepeat = colors.group('magenta'),
    TSLabel = colors.group('blue'),
    TSKeyword = colors.group('magenta'),
    TSKeywordFunction = colors.group('magenta'),
    TSKeywordOperator = colors.group('magenta'),
    TSOperator = colors.group('dimwhite'),
    TSException = colors.group('magenta'),
    TSType = colors.group('blue'),
    TSTypeBuiltin = colors.group('blue'),
    TSStructure = colors.group('brightmagenta'),
    TSInclude = colors.group('magenta'),
    TSVariable = colors.group('cyan'),
    TSVariableBuiltin = colors.group('yellow'),
    TSText = colors.group('brightyellow'),
    TSEmphasis = colors.group('brightyellow'),
    TSUnderline = colors.group('brightyellow'),
    TSTitle = colors.group('brightyellow'),
    TSLiteral = colors.group('brightyellow'),
    TSURI = colors.group('brightyellow'),
    TSTag = colors.group('brightred'),
    TSTagDelimiter = colors.group('brightblack')
  }

  for k, v in pairs(highlight_definitions) do
    bindings.highlight.define(k, v)
  end
end
registry.auto('ColorScheme', color_setup)

registry.install {
  'arcticicestudio/nord-vim',
  config = function (plugin)
    function setup_colorscheme()
      if plugin.installed() and plugin.loaded() then
        api.nvim_command('colorscheme nord')
      else
        vim.defer_fn(setup_colorscheme, 100)
      end
    end
    setup_colorscheme()
  end,
  post_install = function ()
    api.nvim_command('colorscheme nord')
  end
}
