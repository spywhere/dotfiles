local registry = require('lib.registry')

registry.install {
  'lukas-reineke/indent-blankline.nvim',
  config = function ()
    vim.g.indent_blankline_char = '▏'
    vim.g.indent_blankline_use_treesitter = true
    vim.g.indent_blankline_show_current_context = true
    vim.g.indent_blankline_filetype_exclude = { 'text', 'help', 'startify', 'alpha' }
    -- better context scope highlight (https://github.com/lukas-reineke/indent-blankline.nvim/issues/61#issuecomment-803613439)
    vim.g.indent_blankline_context_patterns = {
      'class', 'function', 'method', '^if', '^while',
      '^for', '^object', '^table', 'block', 'arguments'
    }

    vim.g.indent_blankline_space_char = ' '
    vim.g.indent_blankline_space_char_blankline = ' '
  end,
  delay = function ()
    local disable_indent_guides = function ()
      vim.cmd('IndentBlanklineDisable')
    end

    -- disable indentation guides on terminal buffers
    registry.auto('TermOpen', disable_indent_guides)
  end
}
