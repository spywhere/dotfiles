local bindings = require('lib.bindings')
local registry = require('lib.registry')

local bells = function ()
  bindings.set('noerrorbells')
  bindings.set('visualbell')
end
registry.defer(bells)

local timeouts = function ()
  bindings.set('timeoutlen', 500)
  bindings.set('updatetime', 300)
end
registry.defer(timeouts)

local draw = function ()
  bindings.set('lazyredraw')
end
registry.defer(draw)
