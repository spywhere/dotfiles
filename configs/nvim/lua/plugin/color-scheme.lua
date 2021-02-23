local bindings = require('lib/bindings')
local registry = require('lib/registry')

-- registry.install('gruvbox-community/gruvbox')
-- registry.install('joshdick/onedark.vim')
registry.install('arcticicestudio/nord-vim')

local color_setup = function ()
  -- color palettes (from nord-vim)
  -- #2e3440
  -- #3b4252
  -- #434c5e
  -- #4c566a
  -- #d8dee9
  -- #e5e9f0
  -- #eceff4

  -- #8fbcbb
  -- #88c9d9
  -- #81a1c1
  -- #5e81ac
  -- #bf616a
  -- #d98770
  -- #ebcb8b
  -- #a3be8c
  -- #b48ead
  bindings.highlight.define('NordBlack', { guifg='#3b4252' })
  bindings.highlight.define('NordRed', { guifg='#bf616a' })
  bindings.highlight.define('NordGreen', { guifg='#a3be8c' })
  bindings.highlight.define('NordYellow', { guifg='#ebcb8b' })
  bindings.highlight.define('NordBlue', { guifg='#81a1c1' })
  bindings.highlight.define('NordMagenta', { guifg='#b48ead' })
  bindings.highlight.define('NordCyan', { guifg='#88c9d9' })
  bindings.highlight.define('NordWhite', { guifg='#e5e9f0' })

  bindings.highlight.define('NordBrightBlack', { guifg='#4c566a' })
  bindings.highlight.define('NordBrightRed', { guifg='#bf616a' })
  bindings.highlight.define('NordBrightGreen', { guifg='#a3be8c' })
  bindings.highlight.define('NordBrightYellow', { guifg='#ebcb8b' })
  bindings.highlight.define('NordBrightBlue', { guifg='#81a1c1' })
  bindings.highlight.define('NordBrightMagenta', { guifg='#b48ead' })
  bindings.highlight.define('NordBrightCyan', { guifg='#8fbcbb' })
  bindings.highlight.define('NordBrightWhite', { guifg='#eceff4' })

  bindings.highlight.define('NordDimBlack', { guifg='#373e4d' })
  bindings.highlight.define('NordDimRed', { guifg='#94545d' })
  bindings.highlight.define('NordDimGreen', { guifg='#809575' })
  bindings.highlight.define('NordDimYellow', { guifg='#b29e75' })
  bindings.highlight.define('NordDimBlue', { guifg='#68809a' })
  bindings.highlight.define('NordDimMagenta', { guifg='#8c738c' })
  bindings.highlight.define('NordDimCyan', { guifg='#6d96a6' })
  bindings.highlight.define('NordDimWhite', { guifg='#aeb5bb'})

  -- black background
  bindings.highlight.define('Normal', { guibg='#1c1c1c', ctermbg='234' })
  -- invisible splits
  bindings.highlight.define('SignColumn', { guibg='#1c1c1c', ctermbg='234' });
  bindings.highlight.define('VertSplit', { guifg='bg', ctermfg='bg', guibg='#1c1c1c', ctermbg='234' });

  -- color definition (taken from https://github.com/arcticicestudio/nord-vim/issues/235)
  bindings.highlight.link('TSError', 'NordBrightRed')
  bindings.highlight.link('TSPunctDelimiter', 'NordBlue')
  bindings.highlight.link('TSPunctBracket', 'NordBlue')
  bindings.highlight.link('TSPunctSpecial', 'NordBlue')
  bindings.highlight.link('TSConstant', 'NordCyan')
  bindings.highlight.link('TSConstBuiltin', 'NordDimYellow')
  bindings.highlight.link('TSConstMacro', 'NordBrightCyan')
  bindings.highlight.link('TSStringRegex', 'NordGreen')
  bindings.highlight.link('TSString', 'NordGreen')
  bindings.highlight.link('TSStringEscape', 'NordBrightCyan')
  bindings.highlight.link('TSCharacter', 'NordGreen')
  bindings.highlight.link('TSNumber', 'NordDimYellow')
  bindings.highlight.link('TSBoolean', 'NordDimYellow')
  bindings.highlight.link('TSFloat', 'NordGreen')
  bindings.highlight.link('TSAnnotation', 'NordYellow')
  bindings.highlight.link('TSAttribute', 'NordCyan')
  bindings.highlight.link('TSNamespace', 'NordMagenta')
  bindings.highlight.link('TSFuncBuiltin', 'NordBlue')
  bindings.highlight.link('TSFunction', 'NordBlue')
  bindings.highlight.link('TSFuncMacro', 'NordYellow')
  bindings.highlight.link('TSParameter', 'NordBrightCyan')
  bindings.highlight.link('TSParameterReference', 'NordBrightCyan')
  bindings.highlight.link('TSMethod', 'NordBlue')
  bindings.highlight.link('TSField', 'NordBrightRed')
  bindings.highlight.link('TSProperty', 'NordYellow')
  bindings.highlight.link('TSConstructor', 'NordCyan')
  bindings.highlight.link('TSConditional', 'NordMagenta')
  bindings.highlight.link('TSRepeat', 'NordMagenta')
  bindings.highlight.link('TSLabel', 'NordBlue')
  bindings.highlight.link('TSKeyword', 'NordMagenta')
  bindings.highlight.link('TSKeywordFunction', 'NordMagenta')
  bindings.highlight.link('TSKeywordOperator', 'NordMagenta')
  bindings.highlight.link('TSOperator', 'NordDimWhite')
  bindings.highlight.link('TSException', 'NordMagenta')
  bindings.highlight.link('TSType', 'NordBlue')
  bindings.highlight.link('TSTypeBuiltin', 'NordBlue')
  bindings.highlight.link('TSStructure', 'NordBrightMagenta')
  bindings.highlight.link('TSInclude', 'NordMagenta')
  bindings.highlight.link('TSVariable', 'NordCyan')
  bindings.highlight.link('TSVariableBuiltin', 'NordYellow')
  bindings.highlight.link('TSText', 'NordBrightYellow')
  bindings.highlight.link('TSEmphasis', 'NordBrightYellow')
  bindings.highlight.link('TSUnderline', 'NordBrightYellow')
  bindings.highlight.link('TSTitle', 'NordBrightYellow')
  bindings.highlight.link('TSLiteral', 'NordBrightYellow')
  bindings.highlight.link('TSURI', 'NordBrightYellow')
  bindings.highlight.link('TSTag', 'NordBrightRed')
  bindings.highlight.link('TSTagDelimiter', 'NordBrightBlack')
end
registry.auto('ColorScheme', color_setup)

registry.post(function ()
  api.nvim_exec('colorscheme nord', false)
end)
