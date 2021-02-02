local registry = require('lib/registry')

-- registry.install('gruvbox-community/gruvbox')
-- registry.install('joshdick/onedark.vim')
registry.install('arcticicestudio/nord-vim')

local color_setup = function ()
  api.nvim_exec([[
    hi Normal guibg=#1C1C1C ctermbg=234
    hi SignColumn guibg=#1C1C1C ctermbg=234
    hi VertSplit guifg=bg ctermfg=bg guibg=#1C1C1C ctermbg=234
  ]], false)
end
registry.auto('ColorScheme', color_setup)

registry.post(function ()
  api.nvim_exec('colorscheme nord', false)
end)
