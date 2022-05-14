local registry = require('lib.registry')

registry.pre(function ()
  vim.g.do_filetype_lua = 1
  vim.g.did_load_filetypes = 0
end)
