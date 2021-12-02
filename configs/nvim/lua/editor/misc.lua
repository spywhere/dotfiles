local registry = require('lib.registry')

local leader_key = function ()
  vim.g.mapleader = ','
end
registry.pre(leader_key)
