local lsp = require('lib.lsp')

lsp.setup('sqlls')
  .need_executable('sql-language-server')
  .command { 'sql-language-server', 'up', '--method', 'stdio' }
