local registry = require('lib/registry')
local bindings = require('lib/bindings')

registry.install {
  'tpope/vim-unimpaired',
  lazy = true,
  config = function ()
    bindings.map.normal('<A-Up>', '[e', { noremap =false })
    bindings.map.normal('<A-k>', '[e', { noremap =false })
    bindings.map.normal('<A-Down>', ']e', { noremap =false })
    bindings.map.normal('<A-j>', ']e', { noremap =false })

    bindings.map.visual('<A-Up>', '[egv', { noremap =false })
    bindings.map.visual('<A-k>', '[egv', { noremap =false })
    bindings.map.visual('<A-Down>', ']egv', { noremap =false })
    bindings.map.visual('<A-j>', ']egv', { noremap =false })
  end
}
