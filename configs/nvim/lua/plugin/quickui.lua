local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.defer(function ()
  fn['quickui#menu#reset']()

  local menus = {
    ['&File'] = {
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
    },
    ['&Edit'] = {
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
    },
    ['&View'] = {
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
    }
  }

  for menu, items in pairs(menus) do
    fn['quickui#menu#install'](menu, items)
  end

  bindings.map.normal('gk', '<cmd>ContextMenu<cr>')
  bindings.cmd('ContextMenu', {
    function (modifiers)
      local content = {
        { "&Help Keyword\t\\ch", 'echo 100'  },
        { "&Signature\t\\cs", 'echo 101' },
        { '-' },
        { "Find in &File\t\\cx", 'echo 200'  },
        { "Find in &Project\t\\cp", 'echo 300'  },
        { "Find in &Defintion\t\\cd", 'echo 400'  },
        { "Search &References\t\\cr", 'echo 500' },
        { '-' },
        { "&Documentation\t\\cm", 'echo 600' },
      }
      local cursor = { index = vim.g['quickui#context#cursor'] }
      cursor[true] = vim.types.dictionary
      fn['quickui#context#open'](content, cursor)
    end,
  })
end)
