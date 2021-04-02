local bindings = require('lib/bindings')
local registry = require('lib/registry')

local clipboard = function ()
  bindings.set('clipboard', 'unnamed')
end
registry.defer(clipboard)

local tab_expansion = function ()
  local tab_size = 2

  bindings.set('expandtab')
  bindings.set('smarttab')
  bindings.set('smartindent')
  bindings.set('shiftwidth', tab_size)
  bindings.set('tabstop', tab_size)
end
registry.defer(tab_expansion)

local quick_add_line = function ()
  bindings.map.normal('go', 'o<esc>')
  bindings.map.normal('gO', 'O<esc>')
end
registry.defer(quick_add_line)

local move_lines = function ()
  bindings.map.normal('<A-Up>', 'ddkP')
  bindings.map.normal('<A-k>', 'ddkP')
  bindings.map.normal('<A-Down>', 'ddp')
  bindings.map.normal('<A-j>', 'ddp')

  bindings.map.visual('<A-Up>', 'dkP1v')
  bindings.map.visual('<A-k>', 'dkP1v')
  bindings.map.visual('<A-Down>', 'dp1v')
  bindings.map.visual('<A-j>', 'dp1v')
end
registry.defer(move_lines)

local quick_save = function ()
  bindings.map.normal('<leader>w', '<cmd>w<cr>')
end
registry.defer(quick_save)

if fn.has('wsl') == 1 then
  -- use X for visual block since Ctrl-V is paste
  local alternative_visual_block = function ()
    bindings.map.nv('X', '<C-v>')
  end
  registry.defer(alternative_visual_block)
end

local visual_increment = function ()
  bindings.map.visual('<C-a>', 'g<C-a>')
  bindings.map.visual('<C-x>', 'g<C-x>')
  bindings.map.visual('g<C-a>', '<C-a>')
  bindings.map.visual('g<C-x>', '<C-x>')
end
registry.defer(visual_increment)

local sudo_write = function ()
  local write = {
    function()
      api.nvim_command('w !sudo tee %')
    end
  }
  bindings.cmd('WS', write)
  bindings.cmd('SudoWrite', write)
end
registry.defer(sudo_write)

local alternate_digraph = function ()
  bindings.map.insert('<C-d>', '<C-k>')
end
registry.defer(alternate_digraph)
