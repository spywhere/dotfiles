local registry = require('lib.registry')

registry.install {
  'j-hui/fidget.nvim',
  lazy = true,
  config = function ()
    require('fidget').setup {
      text = {
        spinner = 'dots'
      }
    }
  end
}
