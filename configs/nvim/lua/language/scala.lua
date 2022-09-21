local lsp = require('lib.lsp')

lsp.setup('metals')
  .filetypes({ 'scala', 'sbt', 'java' })
  .options(function ()
    return require('metals').bare_config()
  end)
  .auto(function (config)
    config.settings = {}

    require('metals').initialize_or_attach(config)
  end)
