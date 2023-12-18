local registry = require('lib.registry')

registry.install {
  'stevearc/dressing.nvim',
  config = function ()
    require('dressing').setup {
      select = {
        fzf_lua = {
          winopts = {
            height = 15,
            width = 80
          },
          fzf_opts = {
            ['--layout'] = 'reverse'
          }
        }
      }
    }
  end
}
