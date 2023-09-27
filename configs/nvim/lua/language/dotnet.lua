local lsp = require('lib.lsp')

lsp.setup('omnisharp')
  .need_executable('dotnet')
  .options(function ()
    return {
      enable_roslyn_analyzers = true,
      handlers = {
        ['textDocument/definition'] = require('omnisharp_extended').handler
      }
    }
  end)
  .command(function ()
    local command = { 'omnisharp' }
    -- exclude paths
    -- table.insert(command, 'FileOptions:SystemExcludeSearchPatterns:<index>=<path>')
    --
    -- table.insert(command, 'MsBuild:LoadProjectsOnDemand=true')

    -- See: https://github.com/OmniSharp/omnisharp-vscode/blob/1d477d2e0495a9a7d76c7856dc4fe1a46343b7e1/src/omnisharp/server.ts#L380
    table.insert(command, 'RoslynExtensionsOptions:EnableDecompilationSupport=true')
    if fn.executable('asdf') == 1 then
      local sdk = string.gsub(fn.system('asdf where dotnet-core'), '[ \n]*$', '')

      if string.find(sdk, 'No such plugin') == nil then
        table.insert(command, string.format('Sdk:Path=\'%s/sdk\'', sdk))
      end
    end
    return command
  end)
  .on.attach(function (client)
    if client.name ~= 'omnisharp' then
      return
    end

    -- Fix OmniSharp's semantic tokens not conform to spec
    --   Ref: https://nicolaiarocci.com/making-csharp-and-omnisharp-play-well-with-neovim/
    --   Ref: https://github.com/neovim/neovim/issues/21391
    --   Ref: https://github.com/OmniSharp/omnisharp-roslyn/issues/2483
    client.server_capabilities.semanticTokensProvider = {
      full = vim.empty_dict(),
      legend = {
        tokenModifiers = { "static_symbol" },
        tokenTypes = {
          "comment",
          "excluded_code",
          "identifier",
          "keyword",
          "keyword_control",
          "number",
          "operator",
          "operator_overloaded",
          "preprocessor_keyword",
          "string",
          "whitespace",
          "text",
          "static_symbol",
          "preprocessor_text",
          "punctuation",
          "string_verbatim",
          "string_escape_character",
          "class_name",
          "delegate_name",
          "enum_name",
          "interface_name",
          "module_name",
          "struct_name",
          "type_parameter_name",
          "field_name",
          "enum_member_name",
          "constant_name",
          "local_name",
          "parameter_name",
          "method_name",
          "extension_method_name",
          "property_name",
          "event_name",
          "namespace_name",
          "label_name",
          "xml_doc_comment_attribute_name",
          "xml_doc_comment_attribute_quotes",
          "xml_doc_comment_attribute_value",
          "xml_doc_comment_cdata_section",
          "xml_doc_comment_comment",
          "xml_doc_comment_delimiter",
          "xml_doc_comment_entity_reference",
          "xml_doc_comment_name",
          "xml_doc_comment_processing_instruction",
          "xml_doc_comment_text",
          "xml_literal_attribute_name",
          "xml_literal_attribute_quotes",
          "xml_literal_attribute_value",
          "xml_literal_cdata_section",
          "xml_literal_comment",
          "xml_literal_delimiter",
          "xml_literal_embedded_expression",
          "xml_literal_entity_reference",
          "xml_literal_name",
          "xml_literal_processing_instruction",
          "xml_literal_text",
          "regex_comment",
          "regex_character_class",
          "regex_anchor",
          "regex_quantifier",
          "regex_grouping",
          "regex_alternation",
          "regex_text",
          "regex_self_escaped_character",
          "regex_other_escape",
        },
      },
      range = true
    }
  end)
