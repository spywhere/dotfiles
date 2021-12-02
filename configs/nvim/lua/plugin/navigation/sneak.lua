local bindings = require('lib.bindings')
local registry = require('lib.registry')

registry.install {
  'justinmk/vim-sneak',
  defer = function ()
    bindings.map.all('f', '<Plug>Sneak_f', { noremap = false })
    bindings.map.all('F', '<Plug>Sneak_F', { noremap = false })
    bindings.map.all('t', '<Plug>Sneak_t', { noremap = false })
    bindings.map.all('T', '<Plug>Sneak_T', { noremap = false })
    bindings.map.all(';', '<Plug>Sneak_;', { noremap = false })
    bindings.map.all(',', '<Plug>Sneak_,', { noremap = false })
  end
}
