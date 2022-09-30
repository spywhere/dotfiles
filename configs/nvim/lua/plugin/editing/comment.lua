local registry = require('lib.registry')

registry.install {
  'numToStr/Comment.nvim',
  skip = registry.experiment('nerdcommenter').on,
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
