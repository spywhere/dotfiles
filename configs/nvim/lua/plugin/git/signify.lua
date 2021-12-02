local registry = require('lib.registry')

registry.install {
  'mhinz/vim-signify',
  lazy = true,
  config = function ()
    vim.g.signify_sign_show_count = 0
  end
}
