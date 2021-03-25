local bindings = require('lib/bindings')
local registry = require('lib/registry')

local terminal_keymap = function ()
  -- easy exit to normal mode
  bindings.map.terminal('<esc>', '<C-\\><C-n>')
end
-- conflicted with fzf as it's running in terminal mode
-- registry.defer(terminal_keymap)

if fn.has('win32') == 1 and fn.executable('wsl.exe') == 1 then
  local quick_terminal = function ()
    local wsl_terminal = {
      function()
        api.nvim_command('terminal wsl.exe')
      end
    }
    bindings.cmd('WSLTerminal', wsl_terminal)
    bindings.map.normal('<C-a>c', '<cmd>vsplit | WSLTerminal<cr>')
    bindings.map.normal('<C-a><space>', '<cmd>WSLTerminal<cr>')
  end
  registry.defer_first(quick_terminal)
end
