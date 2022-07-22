local registry = require('lib.registry')

-- optional utf8 dependencies for better string manipulation
registry.install {
  'uga-rosa/utf8.nvim',
  delay = function ()
    require('now-playing').setup {}
  end
}
