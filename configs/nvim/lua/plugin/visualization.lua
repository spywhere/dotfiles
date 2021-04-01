local registry = require('lib/registry')

registry.install('lukas-reineke/indent-blankline.nvim', { branch = 'lua' })
-- registry.install('Yggdroot/indentLine', { lazy = 'indentLine' })
registry.post(function ()
  vim.g.indent_blankline_use_treesitter = true
  vim.g.indent_blankline_show_current_context = true
  vim.g.indent_blankline_filetype_exclude = { 'text', 'startify' }

  vim.g.indentLine_leadingSpaceChar = '·'
  -- vim.g.indentLine_fileTypeExclude = { 'text', 'startify' }
end)
registry.defer(function ()
  local disable_indent_guides = function ()
    api.nvim_command('IndentBlanklineDisable')
    -- api.nvim_command('IndentLinesDisable')
  end

  -- disable indentation guides on terminal buffers
  registry.auto('TermOpen', disable_indent_guides)
end)

registry.install(
  'jeffkreeftmeijer/vim-numbertoggle',
  { lazy = 'vim-numbertoggle' }
)
registry.install(
  'AndrewRadev/linediff.vim',
  { lazy = 'linediff.vim' }
)
