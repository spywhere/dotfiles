local registry = require('lib/registry')
local bindings = require('lib/bindings')

registry.install {
  'akinsho/nvim-toggleterm.lua',
  defer = function ()
    local has_wsl = fn.has('win32') == 1 and fn.executable('wsl.exe') == 1
    local shell = vim.o.shell

    if has_wsl then
      shell = 'wsl.exe'
    end

    require('toggleterm').setup({
      shell = shell,
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
