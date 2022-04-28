local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.install {
  'tpope/vim-speeddating',
  config = function ()
    -- disabled as we will map switch.vim and speeddating ourselves
    vim.g.speeddating_no_mappings = 1
  end,
  delay = function ()
    -- avoid issues because of remap belows
    bindings.map.normal('<Plug>SpeedDatingFallbackUp', '<c-a>')
    bindings.map.normal('<Plug>SpeedDatingFallbackDown', '<c-x>')

    -- manually invoke speedating in case switch didn't work
    bindings.map.normal('<c-a>', '<cmd>if !switch#Switch() <bar>call speeddating#increment(v:count1) <bar> endif<cr>')
    bindings.map.normal('<c-x>', '<cmd>if !switch#Switch({\'reverse\': 1}) <bar>call speeddating#increment(-v:count1) <bar> endif<cr>')
  end
}
