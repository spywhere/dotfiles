local registry = require('lib.registry')

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
    require('nvim-treesitter').setup {}

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

      -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- vim.wo.foldmethod = 'expr'

      -- Enable treesitter-based indentation
      -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end)
  end
}
