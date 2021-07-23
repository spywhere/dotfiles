local registry = require('lib/registry')

registry.install {
  'lukas-reineke/indent-blankline.nvim',
  config = function ()
    vim.g.indent_blankline_char = '▏'
    vim.g.indent_blankline_use_treesitter = true
    vim.g.indent_blankline_show_current_context = true
    vim.g.indent_blankline_filetype_exclude = { 'text', 'help', 'startify' }
    -- better context scope highlight (https://github.com/lukas-reineke/indent-blankline.nvim/issues/61#issuecomment-803613439)
    vim.g.indent_blankline_context_patterns = {
      'class', 'function', 'method', '^if', '^while',
      '^for', '^object', '^table', 'block', 'arguments'
    }

    vim.g.indentLine_leadingSpaceChar = '·'
    -- vim.g.indentLine_fileTypeExclude = { 'text', 'startify' }
  end,
  defer = function ()
    local disable_indent_guides = function ()
      api.nvim_command('IndentBlanklineDisable')
      -- api.nvim_command('IndentLinesDisable')
    end

    -- disable indentation guides on terminal buffers
    registry.auto('TermOpen', disable_indent_guides)
  end
}
