local registry = require('lib.registry')

registry.install {
  'wakatime/vim-wakatime',
  lazy = true,
  skip = registry.experiment('no_wakatime').on
}
