local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'akinsho/nvim-toggleterm.lua',
  skip = fn.has('win32') == 1,
  defer = function ()
    require('toggleterm').setup({
      direction = 'float',
      float_opts = {
        border = 'none'
      }
    })


    local Terminal = require('toggleterm.terminal').Terminal
    local fuzzy = function (command)
      return Terminal:new({
        cmd = 'git fuzzy interactive ' .. command,
        hidden = true
      })
    end
    local git_fuzzy = {
      gst = 'status',
      gdd = 'diff',
      gstl = 'stash',
      -- glg = 'log',
      gb = 'branch'
    }

    for map, command in pairs(git_fuzzy) do
      local terminal = fuzzy(command)
      bindings.map.normal(map, function ()
        terminal:toggle()
      end)
    end
  end
}
