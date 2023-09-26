local registry = require('lib.registry')

registry.install {
  'mfussenegger/nvim-lint',
  config = function ()
    require('lint').linters_by_ft = {
      json = { 'jsonlint' },
      js = { 'eslint' },
      jsx = { 'eslint' },
      ts = { 'eslint' },
      tsx = { 'eslint' }
    }

    registry.auto('BufWritePost', function () require('lint').try_lint() end)
  end
}
