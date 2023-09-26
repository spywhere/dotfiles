local registry = require('lib.registry')

registry.install {
  'lukas-reineke/indent-blankline.nvim',
  config = function ()
    require('indent_blankline').setup {
      char = '▏',
      use_treesitter = true,
      show_current_context = true,
      filetype_exclude = {
        'text', 'help', 'startify', 'alpha', 'packer', 'lazy', 'mason'
      },
      buftype_exclude = { 'terminal' },
      -- better context scope highlight (https://github.com/lukas-reineke/indent-blankline.nvim/issues/61#issuecomment-803613439)
      context_patterns = {
        'class', 'function', 'method', '^if', '^while',
        '^for', '^object', '^table', 'block', 'arguments'
      },
      space_char = ' ',
      space_char_blankline = ' '
    }
  end
}
