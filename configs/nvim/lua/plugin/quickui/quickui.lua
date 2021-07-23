local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install {
  'skywind3000/vim-quickui',
  config = function ()
    vim.g.quickui_show_tip = 1
    vim.g.quickui_border_style = 2
    vim.g.quickui_color_scheme = 'papercol dark'
  end,
  defer_first = function ()
    bindings.map.normal('<leader>m', '<cmd>call quickui#menu#open()<cr>')
  end,
  defer = function ()
    fn['quickui#menu#reset']()

    fn['quickui#menu#install']('&File', {
      {
        "&New Buffer\t:enew",
        'enew',
        'Create a new empty buffer in current window'
      },
      {
        "New &Vertical Buffer\t:vnew",
        'vnew',
        'Create a new empty buffer in a new vertical split'
      },
      { '--' },
      {
        "&Save\t,w",
        'write',
        'Save changes on current buffer'
      },
      {
        "Save &All\t:wall",
        'wall',
        'Save changes on all buffers'
      },
      { '--' },
      {
        "&Reload %{&modified?'Unsaved ':''}Buffer\t:edit!",
        'edit!',
        'Reload current buffer'
      },
      {
        "Close &Window\t<C-w>q",
        'close',
        'Close current window'
      },
      {
        "&Close %{&modified?'Unsaved ':''}Buffer\t<A-w>",
        'bdelete!',
        'Close current buffer'
      },
      {
        "Close &Others\t<A-w>",
        '%bd | e# | bd#',
        'Close all buffers including no name except current one'
      }
    })
    fn['quickui#menu#install']('&Edit', {
      {
        "&Undo\tu",
        'undo',
        'Undo the latest change'
      },
      {
        "&Redo\t<C-y>",
        'redo',
        'Redo the latest change'
      },
      { '--' },
      {
        "&Cut\td",
        'delete',
        'Cut the current line into the yank register'
      },
      {
        "Cop&y\ty",
        'yank',
        'Yank the current line into the yank register'
      },
      {
        "&Paste\tp",
        'put',
        'Put the content in yank register after the cursor'
      },
      { '--' },
      {
        "F&ind\t:<leader>/",
        'BLines',
        'Initiate a search mode'
      },
      {
        "&Find in Files\t:<leader>f",
        'Rg',
        'Search for pattern across the project'
      },
      { '--' },
      {
        "Toggle &Line Comment\t<leader>c<space>",
        'call NERDComment("n", "Toggle")',
        'Toggle line comments'
      },
      {
        "Insert &Block Comment\t<leader>cs>",
        'call NERDComment("n", "Sexy")',
        'Insert block comments'
      }
    })
    fn['quickui#menu#install']('&View', {
      {
        " Command &Palette\t:Commands",
        'Commands',
        'Open a command list'
      },
      { '--' },
      {
        "%{exists('w:indentLine_indentLineId') && ! empty(w:indentLine_indentLineId)?'✓':' '}Render &Indent Guides\t:IndentLinesToggle",
        'IndentLinesToggle',
        'Toggle indentation guide lines'
      },
      {
        "%{&list?'✓':' '}&Render Whitespace\t:set invlist",
        'set invlist | LeadingSpaceToggle',
        'Toggle render of whitespace characters'
      },
      {
        "%{&wrap?'✓':' '}&Word Wrap\t:set invwrap",
        'set invwrap',
        'Toggle a word wrap'
      },
      { '--' },
      {
        "%{&spell?'✓':' '}&Spell Check\t:set invspell",
        'set invspell',
        'Toggle a spell check'
      },
      {
        "%{&cursorline?'✓':' '}Cursor &Line\t:set invcursorline",
        'set invcursorline',
        'Toggle render of current cursor line'
      },
      {
        "%{&cursorcolumn?'✓':' '}Cursor &Column\t:set invcursorcolumn",
        'set invcursorcolumn',
        'Toggle render of current cursor column'
      }
    })

    bindings.map.normal('gk', '<cmd>ContextMenu<cr>')
    bindings.cmd('ContextMenu', {
      function ()
        local content = {
          { "Re&name\t<leader>rn", 'lua vim.lsp.buf.rename()' },
          { "&Help Keyword", 'lua vim.cmd("h " .. vim.fn.expand("<cword>"))'  },
          { "&Signature Help\t<C-k>", 'lua vim.lsp.buf.signature_help()' },
          { '-' },
          { "Go to &Defintion\tgd", 'lua vim.lsp.buf.definition()'  },
          { "Go to De&claration\tgD", 'lua vim.lsp.buf.declaration()'  },
          { "Go to &Type Defintion\t<leader>td", 'lua vim.lsp.buf.type_definition()'  },
          { "Search &References\tgr", 'lua vim.lsp.buf.references()' },
          { '-' },
          { "Find in &File\t<leader>/", 'execute "normal" . g:mapleader . "/" . expand("<cword>") | sleep 1m | startinsert!'  },
          { "Find in &Project\t<leader>f", 'execute "normal " . g:mapleader . "f" . expand("<cword>") | sleep 1m | startinsert!'  },
        }
        local cursor = { index = vim.g['quickui#context#cursor'] }
        cursor[true] = vim.types.dictionary
        fn['quickui#context#open'](content, cursor)
      end
    })
  end
}
