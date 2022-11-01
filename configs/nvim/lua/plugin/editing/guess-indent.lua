local registry = require('lib.registry')

registry.install {
  'nmac427/guess-indent.nvim',
  lazy = true,
  config = function ()
    require('guess-indent').setup {}
  end
}
