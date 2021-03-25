local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install('tpope/vim-sleuth', { lazy = 'vim-sleuth' })
registry.install('preservim/nerdcommenter', { lazy = 'nerdcommenter' })
registry.post(function ()
  vim.g.NERDSpaceDelims = 1
end)

registry.install('tpope/vim-repeat')
registry.install('tpope/vim-surround')
registry.install('tpope/vim-unimpaired', { lazy = 'vim-unimpaired' })
registry.install('jiangmiao/auto-pairs')
registry.install('itchyny/vim-parenmatch')
registry.install('christoomey/vim-sort-motion')

registry.install('AndrewRadev/switch.vim')
registry.install('tpope/vim-speeddating')
registry.post(function ()
  -- disabled as we will map switch.vim and speeddating ourselves
  vim.g.speeddating_no_mappings = 1
end)
registry.defer(function ()
  -- avoid issues because of remap belows
  bindings.map.normal('<Plug>SpeedDatingFallbackUp', '<c-a>')
  bindings.map.normal('<Plug>SpeedDatingFallbackDown', '<c-x>')

  -- manually invoke speedating in case switch didn't work
  bindings.map.normal('<c-a>', '<cmd>if !switch#Switch() <bar>call speeddating#increment(v:count1) <bar> endif<cr>')
  bindings.map.normal('<c-x>', '<cmd>if !switch#Switch({\'reverse\': 1}) <bar>call speeddating#increment(-v:count1) <bar> endif<cr>')
end)

registry.install('skywind3000/vim-quickui')
registry.post(function ()
  vim.g.quickui_show_tip = 1
  vim.g.quickui_border_style = 2
  vim.g.quickui_color_scheme = 'papercol dark'
end)
registry.defer_first(function ()
  bindings.map.normal('<leader>m', '<cmd>call quickui#menu#open()<cr>')
  bindings.map.normal('<leader>m', '<cmd>call quickui#menu#open()<cr>')
end)
