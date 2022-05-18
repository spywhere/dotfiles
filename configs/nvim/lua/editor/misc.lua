local registry = require('lib.registry')

local leader_key = function ()
  vim.g.mapleader = ','

  vim.g.loaded_ruby_provider = 0
  vim.g.loaded_perl_provider = 0
end
registry.pre(leader_key)
