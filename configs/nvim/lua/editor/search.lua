local bindings = require('lib/bindings')
local registry = require('lib/registry')

local case_sensitivity = function ()
  bindings.set('ignorecase')
  bindings.set('smartcase')
end
registry.defer(case_sensitivity)

local search_match = function ()
  bindings.set('hlsearch')
  bindings.set('showmatch')
end
registry.pre(search_match)

local clear_highlight = function ()
  bindings.map.normal('<leader>hs', '<cmd>noh<bar>dif<cr>')
end
registry.defer(clear_highlight)
