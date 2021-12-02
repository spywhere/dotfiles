local bindings = require('lib.bindings')
local registry = require('lib.registry')

local split = function ()
  -- split the window to the right / below first
  bindings.set('splitbelow')
  bindings.set('splitright')
end
registry.defer(split)

local horizontal_scrolling = function ()
  bindings.map.nv('gh', '20zh')
  bindings.map.nv('gl', '20zl')
end
registry.defer(horizontal_scrolling)

local quick_close = function ()
  local map_quick_close = function ()
    -- quick close
    bindings.map.buffer.normal('q', '<cmd>wincmd q<cr>')
  end
  registry.auto('FileType', map_quick_close, { 'qf', 'help', 'lspinfo' })
end
registry.defer_first(quick_close)

local quickfix_keymap = function ()
  local map_quickfix = function ()
    -- easy split navigations (not working?)
    bindings.map.buffer.normal('<C-h>', '<cmd>wincmd h<cr>')
    bindings.map.buffer.normal('<C-j>', '<cmd>wincmd j<cr>')
    bindings.map.buffer.normal('<C-k>', '<cmd>wincmd k<cr>')
    bindings.map.buffer.normal('<C-l>', '<cmd>wincmd l<cr>')
  end
  registry.auto('FileType', map_quickfix, { 'qf', 'help' })
end
registry.defer_first(quickfix_keymap)
