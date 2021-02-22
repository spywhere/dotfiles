local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.post(function ()
  if fn.has('termguicolors') then
    bindings.set('termguicolors')
  end
end)

registry.install('norcalli/nvim-colorizer.lua')
registry.post(function ()
  vim.g.vim_markdown_conceal = 0
  vim.g.vim_markdown_conceal_code_blocks = 0
end)
registry.defer(function ()
  require('colorizer').setup()
end)
registry.install('kien/rainbow_parentheses.vim')

if fn.has('nvim-0.5') then
  -- Experimental until nvim-0.5
  registry.install('nvim-treesitter/nvim-treesitter',{
    -- ['do'] = 'TSUpdate'
  })
  registry.post(function ()
    require('nvim-treesitter.configs').setup {
      ensure_installed = 'all',
      highlight = {
        enable = true
      }
    }
  end)
end
