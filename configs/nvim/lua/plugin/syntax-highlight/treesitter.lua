local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
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
    require('nvim-treesitter').setup {
      auto_install = true,
      sync_install = fn.has('linux') == 1,
    }

    local ensure_installed = {
      'bash', 'c', 'c_sharp', 'cpp', 'dockerfile', 'dot', 'graphql',
      'html', 'javascript', 'json', 'json5', 'lua', 'markdown',
      'markdown_inline', 'rust', 'sql', 'toml', 'tsx', 'typescript',
      'vim', 'yaml', 'zig'
    }

    local installed = require('nvim-treesitter.config').get_installed()
    local to_installs = vim.iter(ensure_installed):filter(function(parser)
      return not vim.tbl_contains(installed, parser)
    end):totable()
    require('nvim-treesitter').install(to_installs, {
      max_jobs = fn.has('linux') == 1 and 1 or nil
    })

    registry.auto('FileType', function()
      -- Enable treesitter highlighting and disable regex syntax
      pcall(vim.treesitter.start)

      -- Enable treesitter-based indentation
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end)

    -- bindings.set('foldmethod', 'expr')
    -- bindings.set('foldexpr', 'nvim_treesitter#foldexpr()')
  end
}
