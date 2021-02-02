require('lib/const')
local registry = require('lib/registry')
local loader = require('lib/loader')

loader.explore('editor')
loader.explore('plugin')

local post_install = function ()
  vim.cmd('Startify')
end

registry.post_install(post_install)
registry.startup()
