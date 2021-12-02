local registry = require('lib.registry')

registry.install {
  'preservim/nerdcommenter',
  lazy = true,
  config = function ()
    vim.g.NERDSpaceDelims = 1
  end
}
