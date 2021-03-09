local bindings = require('lib/bindings')
local registry = require('lib/registry')

local terminal_keymap = function ()
  -- easy exit to normal mode
  bindings.map.terminal('<esc>', '<C-\\><C-n>')
end
-- conflicted with fzf as it's running in terminal mode
-- registry.defer(terminal_keymap)
