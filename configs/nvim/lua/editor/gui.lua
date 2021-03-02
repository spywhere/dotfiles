local registry = require('lib/registry')
local bindings = require('lib/bindings')

local windows = function ()
  bindings.map.all('<F11>', '<cmd>call GuiWindowFullScreen(!g:GuiWindowFullScreen)<cr>')
end

if fn.has('win32') == 1 then
  registry.pre(windows)
end
