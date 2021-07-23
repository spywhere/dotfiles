local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install('junegunn/fzf')
registry.install {
  'junegunn/fzf.vim',
  defer_first = function ()
    vim.g.fzf_layout = {
      up = '~90%',
      window = {
        width = 0.9,
        height = 0.9,
        yoffset = 0.5,
        xoffset = 0.5,
        highlight = 'Todo',
        border = 'sharp'
      }
    }
    vim.g.fzf_preview_window =  { 'right:50%', 'ctrl-/' }

    bindings.map.normal('<C-A-p>', '<cmd>Files<cr>')
    bindings.map.normal('<leader><A-/>', '<cmd>BLines<cr>')
    bindings.map.normal('<leader><A-f>', '<cmd>Rg<cr>')
    bindings.map.normal('<leader>F', '<cmd>RG<cr>')
    bindings.map.normal('<leader><A-F>', '<cmd>RG!<cr>')
  end,
  defer = function ()
    local layout = {
      options = { '--layout=reverse' },
      window = {
        width = 1,
        height = 0.4,
        yoffset = 1
      }
    }
    layout[true] = vim.types.dictionary

    local rg_command = table.concat({
      'rg',
      '--column',
      '--line-number',
      '--hidden',
      '--smart-case',
      '--no-heading',
      '--color=always',
      '%s'
    }, ' ')

    bindings.cmd('Files', {
      function (modifiers)
        local preview = fn['fzf#vim#with_preview']
        if modifiers[1] == '' then
          fn['fzf#vim#files'](0, preview())
        else
          fn['fzf#vim#files'](0, preview(layout))
        end
      end,
      bang = true,
      '-nargs=*'
    })

    bindings.cmd('BLines', {
      function (modifiers)
        if modifiers[1] == '' then
          fn['fzf#vim#buffer_lines']('')
        else
          fn['fzf#vim#buffer_lines']('', layout)
        end
      end,
      bang = true,
      '-nargs=*'
    })

    bindings.cmd('Rg', {
      function (modifiers)
        local default_layout = {
          options = '--delimiter : --nth 4..'
        }
        if modifiers[1] ~= '' then
          default_layout = vim.tbl_extend('keep', default_layout, layout)
        end
        default_layout[true] = vim.types.dictionary
        local preview = fn['fzf#vim#with_preview'](default_layout)
        fn['fzf#vim#grep'](
          string.format(rg_command, string.format('%q', modifiers.args)),
          1,
          preview
        )
      end,
      bang = true,
      '-nargs=*'
    })

    bindings.cmd('RG', {
      function (modifiers)
        local command = string.format(rg_command, '-- %s || true')
        local initial_command = string.format(
          command,
          string.format('%q', modifiers.args)
        )
        local reload_command = string.format(
          command,
          '{q}'
        )

        local default_layout = {
          options = {
            '--prompt=RG> ',
            '--phony',
            '--query',
            modifiers.args,
            '--bind',
            'change:reload:' .. reload_command
          }
        }
        if modifiers[1] ~= '' then
          default_layout = vim.tbl_extend('keep', default_layout, layout)
        end
        default_layout[true] = vim.types.dictionary
        local preview = fn['fzf#vim#with_preview'](default_layout)

        fn['fzf#vim#grep'](
          initial_command,
          1,
          preview
        )
      end,
      bang = true,
      '-nargs=*'
    })
  end
}
registry.install('stsewd/fzf-checkout.vim')
