local bindings = require('lib/bindings')
local registry = require('lib/registry')

local split_management = function ()
  -- split resize
  bindings.map.normal('<A-S-Left>', '<cmd>vertical resize -5<cr>')
  bindings.map.normal('<A-S-Right>', '<cmd>vertical resize +5<cr>')
  bindings.map.normal('<A-S-Up>', '<cmd>resize -5<cr>')
  bindings.map.normal('<A-S-Down>', '<cmd>resize +5<cr>')
  bindings.map.normal('<Left>', '<cmd>vertical resize -1<cr>')
  bindings.map.normal('<Right>', '<cmd>vertical resize +1<cr>')
  bindings.map.normal('<Up>', '<cmd>resize -1<cr>')
  bindings.map.normal('<Down>', '<cmd>resize +1<cr>')

  -- quick split
  bindings.map.normal('<leader><Left>', '<cmd>topleft vnew<cr>')
  bindings.map.normal('<leader><Right>', '<cmd>botright vnew<cr>')
  bindings.map.normal('<leader><Up>', '<cmd>topleft new<cr>')
  bindings.map.normal('<leader><Down>', '<cmd>botright new<cr>')
  bindings.map.normal('<leader><Up><Left>', '<cmd>leftabove vnew<cr>')
  bindings.map.normal('<leader><Up><Right>', '<cmd>rightbelow vnew<cr>')
  bindings.map.normal('<leader><Down><Left>', '<cmd>rightbelow new<cr>')
  bindings.map.normal('<leader><Down><Right>', '<cmd>leftabove new<cr>')
end
registry.defer(split_management)

local buffer_management = function ()
  -- switch buffer
  bindings.map.normal('<A-Left>', '<cmd>bprev<cr>')
  bindings.map.normal('<A-Right>', '<cmd>bnext<cr>')

  -- close current buffer
  bindings.map.normal('<A-w>', '<cmd>bdelete<cr>')
  -- close all buffers
  bindings.map.normal('<A-W>', '<cmd>%bd <bar> e# <bar> bd#<cr>')
end
registry.defer(buffer_management)
