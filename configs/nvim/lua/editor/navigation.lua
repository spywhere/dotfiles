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

local quickfix_keymap = function ()
  local map_quickfix = function ()
    -- quick close
    bindings.map.buffer.normal('q', '<cmd>wincmd q<cr>')
    -- easy split navigations (not working?)
    bindings.map.buffer.normal('<C-h>', '<cmd>wincmd h<cr>')
    bindings.map.buffer.normal('<C-j>', '<cmd>wincmd j<cr>')
    bindings.map.buffer.normal('<C-k>', '<cmd>wincmd k<cr>')
    bindings.map.buffer.normal('<C-l>', '<cmd>wincmd l<cr>')
  end
  registry.auto({ 'BufEnter', 'FileType' }, map_quickfix, { 'qf', 'help' })
end
registry.defer(quickfix_keymap)
