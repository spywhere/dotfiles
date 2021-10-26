local registry = require('lib/registry')

if fn.has('nvim-0.5') == 1 then
  registry.install {
    'spywhere/detect-language.nvim',
    config = function ()
      require('detect-language').setup {
        events = {}
      }
    end
  }
end
