local registry = require('lib.registry')

registry.install {
  'kristijanhusak/vim-dadbod-ui',
  requires = 'tpope/vim-dadbod',
  setup = function ()
    vim.g.db_ui_show_help = 0
    vim.g.db_ui_auto_execute_table_helpers = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_use_nerd_fonts = 1
  end
}
