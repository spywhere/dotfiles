local lsp = require('lib.lsp')

local function status_handler(_, status, ctx)
  local val = {}
  if status.hide then
    val = {kind = 'end'}
  elseif status.show then
    val = {kind = 'begin', message = status.text, title='metals'}
  elseif status.text then
    val = {kind = 'report', message = status.text, title='metals'}
  else
    return
  end
  local info = {client_id = ctx.client_id}
  local msg = {token = 'metals', value = val}
  -- call fidget progress handler
  vim.lsp.handlers['$/progress'](nil, msg, info)
end

lsp.setup('metals')
  .filetypes({ 'scala', 'sbt', 'java' })
  .options(function ()
    local config = require('metals').bare_config()

    config.init_options.statusBarProvider = 'on'
    config.handlers['metals/status'] = status_handler

    return config
  end)
  .auto(function (config)
    config.settings = {
      showImplicitArguments = true,
      showImplicitConversionsAndClasses = true,
      showInferredType = true
    }

    require('metals').initialize_or_attach(config)
  end)
