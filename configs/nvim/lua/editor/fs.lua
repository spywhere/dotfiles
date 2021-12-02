local bindings = require('lib.bindings')
local registry = require('lib.registry')

local ignore = function ()
  bindings.set('wildignore', '*.o,*~,*.pyc')
end
registry.defer(ignore)

local backup = function ()
  bindings.set('nobackup')
  bindings.set('nowritebackup')
  bindings.set('noswapfile')
end
registry.defer(backup)

local detection = function ()
  -- auto read the file on changes
  bindings.set('autoread')

  -- file format detection
  bindings.set('ffs', 'unix,dos,mac')
end
registry.defer(detection)
