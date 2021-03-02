local bindings = require('lib/bindings')
local registry = require('lib/registry')

-- registry.install('gruvbox-community/gruvbox')
-- registry.install('joshdick/onedark.vim')
registry.install('arcticicestudio/nord-vim')

local color_setup = function ()
  -- color palettes (from nord-vim)
  -- #2e3440 237  nord0 bg
  -- #3b4252 238  nord1
  -- #434c5e 239  nord2
  -- #4c566a 240  nord3
  -- #d8dee9      nord4 fg
  -- #e5e9f0 255  nord5
  -- #eceff4 255  nord6

  -- #8fbcbb 109  nord7
  -- #88c0d0 110  nord8
  -- #81a1c1 109  nord9
  -- #5e81ac  67  nord10
  -- #bf616a 131  nord11
  -- #d98770      nord12
  -- #ebcb8b 222  nord13
  -- #a3be8c 144  nord14
  -- #b48ead 139  nord15
  --
  -- #616e88  60  nord3-bright
  -- #5c6370 241  line-gray
  -- #2c323c      cursor-gray
  -- #3b4048 238  special-gray
  local definitions = {
    black = { gui='#3b4252', cterm='238' },
    red = { gui='#bf616a', cterm='131' },
    green = { gui='#a3be8c', cterm='144' },
    yellow = { gui='#ebcb8b', cterm='222' },
    blue = { gui='#81a1c1', cterm='109' },
    magenta = { gui='#b48ead', cterm='139' },
    cyan = { gui='#88c0d0', cterm='110' },
    white = { gui='#e5e9f0', cterm='255' },

    brightblack = { gui='#4c566a', cterm='240' },
    brightred = 'red',
    brightgreen = 'green',
    brightyellow = 'yellow',
    brightblue = 'blue',
    brightmagenta = 'magenta',
    brightcyan = { gui='#8fbcbb', cterm='109' },
    brightwhite = { gui='#eceff4', cterm='255' },

    dimblack = { gui='#373e4d' },
    dimred = { gui='#94545d' },
    dimgreen = { gui='#809575' },
    dimyellow = { gui='#b29e75' },
    dimblue = { gui='#68809a' },
    dimmagenta = { gui='#8c738c' },
    dimcyan = { gui='#6d96a6' },
    dimwhite = { gui='#aeb5bb' }
  }

  local function resolve_color_definition(name)
    if not definitions[name] then
      return { gui='NONE', cterm='NONE' }
    end
    local color = definitions[name]
    if type(color) == 'string' then
      return resolve_color_definition(color)
    end
    return color
  end

  local color_group = function (fg, bg)
    local group = {}

    if type(fg) == 'string' and definitions[fg] then
      local color = resolve_color_definition(fg)
      group.guifg=color.gui
      group.ctermfg=color.cterm
    end
    if type(bg) == 'string' and definitions[bg] then
      local color = resolve_color_definition(bg)
      group.guibg=color.gui
      group.ctermbg=color.cterm
    end
    return group
  end

  local base_highlights = {
    -- dark background
    Normal = { guibg='#1c1c1c', ctermbg='234' },
    -- invisible splits
    SignColumn = { guibg='#1c1c1c', ctermbg='234' },
    VertSplit = { guifg='1c1c1c', ctermfg='234', guibg='#1c1c1c', ctermbg='234' }
  }

  for k, v in pairs(base_highlights) do
    bindings.highlight.define(k, v)
  end

  local highlight_definitions = {
    -- color definition (taken from https://github.com/arcticicestudio/nord-vim/issues/235)
    TSError = color_group('brightred'),
    TSPunctDelimiter = color_group('blue'),
    TSPunctBracket = color_group('blue'),
    TSPunctSpecial = color_group('blue'),
    TSConstant = color_group('cyan'),
    TSConstBuiltin = color_group('dimyellow'),
    TSConstMacro = color_group('brightcyan'),
    TSStringRegex = color_group('green'),
    TSString = color_group('green'),
    TSStringEscape = color_group('brightcyan'),
    TSCharacter = color_group('green'),
    TSNumber = color_group('dimyellow'),
    TSBoolean = color_group('dimyellow'),
    TSFloat = color_group('green'),
    TSAnnotation = color_group('yellow'),
    TSAttribute = color_group('cyan'),
    TSNamespace = color_group('magenta'),
    TSFuncBuiltin = color_group('blue'),
    TSFunction = color_group('blue'),
    TSFuncMacro = color_group('yellow'),
    TSParameter = color_group('brightcyan'),
    TSParameterReference = color_group('brightcyan'),
    TSMethod = color_group('blue'),
    TSField = color_group('brightred'),
    TSProperty = color_group('yellow'),
    TSConstructor = color_group('cyan'),
    TSConditional = color_group('magenta'),
    TSRepeat = color_group('magenta'),
    TSLabel = color_group('blue'),
    TSKeyword = color_group('magenta'),
    TSKeywordFunction = color_group('magenta'),
    TSKeywordOperator = color_group('magenta'),
    TSOperator = color_group('dimwhite'),
    TSException = color_group('magenta'),
    TSType = color_group('blue'),
    TSTypeBuiltin = color_group('blue'),
    TSStructure = color_group('brightmagenta'),
    TSInclude = color_group('magenta'),
    TSVariable = color_group('cyan'),
    TSVariableBuiltin = color_group('yellow'),
    TSText = color_group('brightyellow'),
    TSEmphasis = color_group('brightyellow'),
    TSUnderline = color_group('brightyellow'),
    TSTitle = color_group('brightyellow'),
    TSLiteral = color_group('brightyellow'),
    TSURI = color_group('brightyellow'),
    TSTag = color_group('brightred'),
    TSTagDelimiter = color_group('brightblack')
  }

  for k, v in pairs(highlight_definitions) do
    bindings.highlight.define(k, v)
  end
end
registry.auto('ColorScheme', color_setup)

registry.post(function ()
  api.nvim_exec('colorscheme nord', false)
end)
