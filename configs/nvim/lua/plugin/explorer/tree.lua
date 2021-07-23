local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install('kyazdani42/nvim-web-devicons')
registry.install {
  'kyazdani42/nvim-tree.lua',
  config = function ()
    vim.g.nvim_tree_icons = {
      default = ' '
    }
    vim.g.nvim_tree_ignore = { '.git', '.DS_Store' }
    vim.g.nvim_tree_follow = 1
  end,
  defer_first = function ()
    local show_cursorline = function ()
      vim.wo.cursorline = true
    end
    -- show cursorline when browsing in the tree explorer
    registry.auto({ 'BufEnter', 'CursorHold', 'FileType' }, show_cursorline, 'NvimTree')

    bindings.map.all('<leader>e', '<cmd>NvimTreeToggle<cr>')
    bindings.map.all('<leader>E', '<cmd>NvimTreeFindFile<cr>')
  end
}
