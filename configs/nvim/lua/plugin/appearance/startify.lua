local registry = require('lib.registry')

registry.install {
  'mhinz/vim-startify',
  post_install = function ()
    vim.cmd('Startify')
    vim.defer_fn(function ()
      api.nvim_command('IndentBlanklineDisable')
    end, 100)
  end,
  config = function ()
    vim.g.startify_files_number = 20
    vim.g.startify_fortune_use_unicode = 1
    vim.g.startify_enable_special = 0
    vim.g.startify_custom_header = 'startify#center(startify#fortune#cowsay())'
    vim.g.startify_change_to_dir = 0

    vim.g.startify_lists = {
      { type = 'dir',   header = { '   MRU ' .. fn.getcwd() } },
      { type = 'files', header = { '   MRU' } }
    }

    local get_icon = function (path)
      local devicons = require('nvim-web-devicons')
      local filename = fn.fnamemodify(path, ':t')
      local extension = fn.fnamemodify(path, ':e')
      local icon = devicons.get_icon(filename, extension, { default = true })
      if icon then
        return icon.." "
      else
        return ""
      end
    end

    registry.fn(
      { name = 'StartifyEntryFormat' },
      function ()
        local call = {
          registry.call_for_fn(get_icon, { 'absolute_path' }),
          '" "',
          'entry_path'
        }
        return table.concat(call, ' . ')
      end
    )
  end
}
