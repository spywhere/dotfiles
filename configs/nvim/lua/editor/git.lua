local bindings = require('lib/bindings')
local registry = require('lib/registry')

local diff = function ()
  bindings.set('diffopt', '+=', 'vertical')
end
registry.defer(diff)
