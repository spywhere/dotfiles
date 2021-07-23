local registry = require('lib/registry')

registry.install {
  'airblade/vim-rooter',
  config = function ()
    vim.g.rooter_silent_chdir = 1
  end
}
