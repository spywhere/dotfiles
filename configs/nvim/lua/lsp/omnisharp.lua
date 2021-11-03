local lsp = require('lib/lsp')

lsp.setup('omnisharp')
  .need_executable('omnisharp')
  .command(function ()
    local command = { 'omnisharp' }
    local pid = fn.getpid()
    -- solution
    -- table.insert(command, '-s')
    -- table.insert(command, '<path to sln file>')
    table.insert(command, '--languageserver')
    table.insert(command, '--hostPID')
    table.insert(command, tostring(pid))
    -- exclude paths
    -- table.insert(command, 'FileOptions:SystemExcludeSearchPatterns:<index>=<path>')
    -- table.insert(command, 'MsBuild:LoadProjectsOnDemand=true')
    -- table.insert(command, 'RoslynExtensionsOptions:EnableAnalyzersSupport=true')
    -- table.insert(command, 'FormattingOptions:EnableEditorConfigSupport=true')
    -- table.insert(command, 'RoslynExtensionsOptions:EnableDecompilationSupport=true')
    return command
  end)
