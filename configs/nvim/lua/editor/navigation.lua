local bindings = require('lib/bindings')
local registry = require('lib/registry')

local split = function ()
  -- split the window to the right / below first
  bindings.set('splitbelow')
  bindings.set('splitright')
end
registry.defer(split)

local horizontal_scrolling = function ()
  bindings.map.normal('gh', '20zh')
  bindings.map.normal('gl', '20zl')
end
registry.defer(horizontal_scrolling)
