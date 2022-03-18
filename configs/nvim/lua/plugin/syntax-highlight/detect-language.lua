local registry = require('lib.registry')

registry.install {
  'spywhere/detect-language.nvim',
  config = function ()
    require('detect-language').setup {
      events = {}
    }
  end
}
