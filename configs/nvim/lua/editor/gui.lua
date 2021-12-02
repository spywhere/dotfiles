local registry = require('lib.registry')
local bindings = require('lib.bindings')

local windows = function ()
  bindings.map.all('<F11>', '<cmd>call GuiWindowFullScreen(!g:GuiWindowFullScreen)<cr>')

  bindings.map.normal('<C-=>', '<cmd>GuiFont! JetBrainsMono Nerd Font Mono:h12<cr>')
  bindings.map.normal('<C-0>', '<cmd>GuiFont! JetBrainsMono Nerd Font Mono:h9<cr>')
end

local gui = function ()
  -- use TUI tabline instead
  api.nvim_command('GuiTabline 0')
  -- use TUI completion menu instead
  api.nvim_command('GuiPopupmenu 0')
  api.nvim_command('GuiFont! JetBrainsMono Nerd Font Mono:h9')

  bindings.set('mouse', 'a')
end

registry.defer(function ()
  if fn.exists('g:GuiLoaded') == 1 then
    gui()

    if fn.has('win32') == 1 then
      windows()
    end
  end
end)
