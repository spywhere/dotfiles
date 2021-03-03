local registry = require('lib/registry')
local bindings = require('lib/bindings')

local windows = function ()
  bindings.map.all('<F11>', '<cmd>call GuiWindowFullScreen(!g:GuiWindowFullScreen)<cr>')
end

local gui = function ()
  -- use TUI tabline instead
  api.nvim_command('GuiTabline 0')
  -- use TUI completion menu instead
  api.nvim_command('GuiPopupmenu 0')
  api.nvim_command('GuiFont! JetBrainsMono Nerd Font Mono:h9')
end

if fn.exists('g:GuiLoaded') then
  registry.defer(gui)

  if fn.has('win32') == 1 then
    registry.pre(windows)
  end
end
