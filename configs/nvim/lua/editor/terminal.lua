local bindings = require('lib/bindings')
local registry = require('lib/registry')

local terminal_keymap = function ()
  -- easy exit to normal mode
  bindings.map.terminal('<esc>', '<C-\\><C-n>')
end
registry.defer(terminal_keymap)
