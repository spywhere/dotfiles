local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'nvim-treesitter/nvim-treesitter',
  run = function ()
    if fn.exists(':TSUpdate') == 0 then
      return
    end

    if fn.has('linux') == 1 then
      vim.cmd('TSUpdateSync')
    else
      vim.cmd('TSUpdate')
    end
  end,
  config = function ()
    require('nvim-treesitter.configs').setup {
      auto_install = true,
      sync_install = fn.has('linux') == 1,
      ensure_installed = {
        'bash', 'c', 'c_sharp', 'cpp', 'dockerfile', 'dot', 'graphql',
        'html', 'javascript', 'json', 'json5', 'jsonc', 'lua', 'markdown',
        'markdown_inline', 'rust', 'sql', 'toml', 'tsx', 'typescript',
        'vim', 'yaml', 'zig'
      },
      highlight = {
        enable = true
      }
    }

    -- bindings.set('foldmethod', 'expr')
    -- bindings.set('foldexpr', 'nvim_treesitter#foldexpr()')
  end
}
