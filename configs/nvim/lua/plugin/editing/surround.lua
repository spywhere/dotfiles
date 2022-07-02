local registry = require('lib.registry')

registry.install {
  'tpope/vim-surround',
  skip = registry.experiment('surround').on
}

registry.install {
  'kylechui/nvim-surround',
  skip = registry.experiment('surround').off,
  config = function ()
    require('nvim-surround').setup {}
  end
}
