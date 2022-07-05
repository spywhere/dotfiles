local bindings = require('lib.bindings')
local registry = require('lib.registry')

if fn.has('win32') == 1 and fn.executable('wsl.exe') == 1 then
  local quick_terminal = function ()
    local wsl_terminal = {
      function()
        vim.cmd('terminal wsl.exe')
      end
    }
    bindings.cmd('WSLTerminal', wsl_terminal)
    bindings.map.normal('<C-a>c', '<cmd>WSLTerminal<cr>')
    bindings.map.normal('<C-a>-', '<cmd>split | WSLTerminal<cr>')
    bindings.map.normal('<C-a><bar>', '<cmd>vsplit | WSLTerminal<cr>')
    bindings.map.normal('<C-a><space>', '<cmd>WSLTerminal<cr>')
  end
  registry.defer_first(quick_terminal)
end

local terminal_setup = function ()
  registry.auto('TermOpen', function ()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.cmd('startinsert!')
  end)
end
registry.defer_first(terminal_setup)
