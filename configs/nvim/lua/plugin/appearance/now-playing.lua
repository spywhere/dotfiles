local registry = require('lib.registry')

registry.install {
  'spywhere/now-playing.nvim',
  delay = function ()
    require('now-playing').setup {}
  end
}
