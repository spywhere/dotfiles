local registry = require('lib.registry')

registry.install {
  'spywhere/now-playing.nvim',
  requires = {
    {
      -- optional utf8 dependencies for better string manipulation
      'uga-rosa/utf8.nvim',
    }
  },
  delay = function ()
    require('now-playing').setup {}
  end
}
