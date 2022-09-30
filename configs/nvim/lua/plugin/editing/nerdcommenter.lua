local registry = require('lib.registry')

registry.install {
  'preservim/nerdcommenter',
  skip = registry.experiment('nerdcommenter').off,
  lazy = true,
  config = function ()
    vim.g.NERDSpaceDelims = 1
  end
}
