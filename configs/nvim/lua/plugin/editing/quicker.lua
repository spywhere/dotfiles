local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'stevearc/quicker.nvim',
  config = function ()
    require('quicker').setup {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    }

    bindings.map.normal('<leader>q', function ()
      require('quicker').toggle()
    end)
    bindings.map.normal('<leader>l', function ()
      require('quicker').toggle { loclist = true }
    end)
  end
}
