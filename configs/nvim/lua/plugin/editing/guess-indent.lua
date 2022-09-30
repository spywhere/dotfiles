local registry = require('lib.registry')

registry.install {
  'nmac427/guess-indent.nvim',
  skip = registry.experiment('guess-indent').off,
  lazy = true,
  config = function ()
    require('guess-indent').setup {}
  end
}
