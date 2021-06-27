local registry = require('lib/registry')
local bindings = require('lib/bindings')

registry.install {
  'mhinz/vim-signify',
  lazy = true,
  config = function ()
    vim.g.signify_sign_show_count = 0
  end
}

registry.install {
  'tpope/vim-fugitive',
  -- experimental
  -- 'TimUntersberger/neogit',
  lazy = true,
  config = function ()
    bindings.map.normal('gst', '<cmd>Git<cr>')
    -- bindings.map.normal('gst', '<cmd>Neogit<cr>')
    bindings.map.normal('gdd', '<cmd>Git diff<cr>')
    -- bindings.map.normal('gdd', '<cmd>Neogit diff<cr>')
    bindings.map.normal('gds', '<cmd>Git diff --staged<cr>')
  end
}

registry.install('itchyny/vim-gitbranch')
registry.install {
  'rhysd/git-messenger.vim',
  lazy = true
}
