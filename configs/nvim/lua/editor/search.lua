local bindings = require('lib/bindings')
local registry = require('lib/registry')

local case_sensitivity = function ()
  bindings.set('ignorecase')
  bindings.set('smartcase')

  bindings.set('hlsearch')
  bindings.set('showmatch')
end
registry.defer(case_sensitivity)

local clear_highlight = function ()
  bindings.map.normal('<leader>hs', '<cmd>noh<cr>')
end
registry.defer(clear_highlight)
