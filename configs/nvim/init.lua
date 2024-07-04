require('lib.const')
local registry = require('lib.registry')
local loader = require('lib.loader')

registry.startup(function ()
  if vim.g.neovide then
    require('plugin.color-scheme')
    require('plugin.appearance.now-playing')
    loader.explore('neovide', true)
    return
  end
  loader.explore('polyfill')
  loader.explore('editor')
  loader.explore('language')
  loader.explore('plugin', true)
end)
