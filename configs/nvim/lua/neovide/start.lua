local registry = require('lib.registry')

registry.pre(function ()
  vim.cmd('cd ~')
end)
