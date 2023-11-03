local bindings = require('lib.bindings')
local registry = require('lib.registry')

local quick_terminal = function ()
  bindings.map.normal('<leader>t', '<cmd>25split | terminal<cr>')
end
registry.defer_first(quick_terminal)

local terminal_setup = function ()
  registry.auto('TermOpen', function ()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn='no'
    vim.cmd('startinsert!')
  end)
end
registry.defer_first(terminal_setup)
