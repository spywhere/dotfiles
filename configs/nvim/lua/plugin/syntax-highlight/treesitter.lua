local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'nvim-treesitter/nvim-treesitter',
  options = {
    ['do'] = function (info)
      if info.status == 'installed' then
        return
      end

      if fn.has('linux') == 1 then
        vim.cmd('TSUpdateSync')
      else
        vim.cmd('TSUpdate')
      end
    end
  },
  config = function ()
    require('nvim-treesitter.configs').setup {
      auto_install = true,
      highlight = {
        enable = true
      }
    }

    bindings.set('foldmethod', 'expr')
    bindings.set('foldexpr', 'nvim_treesitter#foldexpr()')
  end
}
