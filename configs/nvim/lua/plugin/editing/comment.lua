local registry = require('lib.registry')

registry.install {
  'numToStr/Comment.nvim',
  config = function ()
    require('Comment').setup {
      toggler = {
        line = '<leader>c<space>',
        block = '<leader>cs'
      },
      mappings = {
        extra = false
      }
    }
  end
}
