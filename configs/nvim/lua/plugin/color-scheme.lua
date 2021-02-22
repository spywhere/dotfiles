local bindings = require('lib/bindings')
local registry = require('lib/registry')

-- registry.install('gruvbox-community/gruvbox')
-- registry.install('joshdick/onedark.vim')
registry.install('arcticicestudio/nord-vim')

local color_setup = function ()
  bindings.highlight.define('Normal', { guibg='#1c1c1c', ctermbg='234' })
  bindings.highlight.define('SignColumn', { guibg='#1c1c1c', ctermbg='234' });
  bindings.highlight.define('VertSplit', { guifg='bg', ctermfg='bg', guibg='#1c1c1c', ctermbg='234' });
  bindings.highlight.define('TSError', { ctermfg='203', guifg='#f44747' });
  bindings.highlight.define('TSPunctDelimiter', { ctermfg='249', guifg='#abb2bf' });
  bindings.highlight.define('TSPunctBracket', { ctermfg='249', guifg='#abb2bf' });
  bindings.highlight.define('TSPunctSpecial', { ctermfg='249', guifg='#abb2bf' });
  bindings.highlight.define('TSConstant', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSConstBuiltin', { ctermfg='173', guifg='#d19a66' });
  bindings.highlight.define('TSConstMacro', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSStringRegex', { ctermfg='114', guifg='#98c379' });
  bindings.highlight.define('TSString', { ctermfg='114', guifg='#98c379' });
  bindings.highlight.define('TSStringEscape', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSCharacter', { ctermfg='114', guifg='#98c379' });
  bindings.highlight.define('TSNumber', { ctermfg='173', guifg='#d19a66' });
  bindings.highlight.define('TSBoolean', { ctermfg='173', guifg='#d19a66' });
  bindings.highlight.define('TSFloat', { ctermfg='114', guifg='#98c379' });
  bindings.highlight.define('TSAnnotation', { ctermfg='180', guifg='#e5c07b' });
  bindings.highlight.define('TSAttribute', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSNamespace', { ctermfg='201', guifg='#ff00ff' });
  bindings.highlight.define('TSFuncBuiltin', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSFunction', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSFuncMacro', { ctermfg='180', guifg='#e5c07b' });
  bindings.highlight.define('TSParameter', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSParameterReference', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSMethod', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSField', { ctermfg='168', guifg='#e06c75' });
  bindings.highlight.define('TSProperty', { ctermfg='180', guifg='#e5c07b' });
  bindings.highlight.define('TSConstructor', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSConditional', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSRepeat', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSLabel', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSKeyword', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSKeywordFunction', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSKeywordOperator', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSOperator', { ctermfg='249', guifg='#abb2bf' });
  bindings.highlight.define('TSException', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSType', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSTypeBuiltin', { ctermfg='75', guifg='#61afef' });
  bindings.highlight.define('TSStructure', { ctermfg='201', guifg='#ff00ff' });
  bindings.highlight.define('TSInclude', { ctermfg='175', guifg='#c586c0' });
  bindings.highlight.define('TSVariable', { ctermfg='73', guifg='#56b6c2' });
  bindings.highlight.define('TSVariableBuiltin', { ctermfg='180', guifg='#e5c07b' });
  bindings.highlight.define('TSText', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSStrong', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSEmphasis', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSUnderline', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSTitle', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSLiteral', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSURI', { ctermfg='226', guifg='#ffff00' });
  bindings.highlight.define('TSTag', { ctermfg='168', guifg='#e06c75' });
  bindings.highlight.define('TSTagDelimiter', { ctermfg='241', guifg='#5c6370' });
end
registry.auto('ColorScheme', color_setup)

registry.post(function ()
  api.nvim_exec('colorscheme nord', false)
end)
