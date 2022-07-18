local registry = require('lib.registry')

registry.defer(function ()
  require('now-playing').setup {}
end)
