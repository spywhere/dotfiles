require('lib/const')
local registry = require('lib/registry')
local loader = require('lib/loader')

loader.explore('editor')
loader.explore('plugin')

registry.startup()
