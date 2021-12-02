local registry = require('lib.registry')
local bindings = require('lib.bindings')

registry.install {
  'L3MON4D3/LuaSnip',
  config = function ()
    if registry.experiment('cmp').off() then
      local luasnip = prequire('luasnip')

      local t = function (str)
        return api.nvim_replace_termcodes(str, true, true, true)
      end

      local tab_completion = function ()
        if fn.pumvisible() == 1 then
          return t "<C-n>"
        elseif luasnip and luasnip.expand_or_jumpable() then
          return t "<Plug>luasnip-expand-or-jump"
        else
          return t "<Tab>"
        end
      end

      local shift_tab_completion = function ()
        if fn.pumvisible() == 1 then
          return t "<C-p>"
        elseif luasnip and luasnip.jumpable(-1) then
          return t "<Plug>luasnip-jump-prev"
        else
          return t "<S-Tab>"
        end
      end

      bindings.map.insert(
        '<tab>',
        registry.call_for_fn(tab_completion),
        { expr = true }
      )
      bindings.map.insert(
        '<S-tab>',
        registry.call_for_fn(shift_tab_completion),
        { expr = true }
      )
    end

    require("luasnip/loaders/from_vscode").lazy_load()
  end
}
