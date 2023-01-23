-- common constants
api = vim.api
env = vim.env
fn = vim.fn
luv = vim.loop

plug_nvim_url = 'https://raw.githubusercontent.com/spywhere/plug.nvim/main/plug.lua'
config_home = fn.stdpath('config')
pack_site = fn.stdpath('data') .. '/site/pack'

lua_home = config_home .. '/lua'
plug_nvim_path = pack_site .. '/plug/start/plug.nvim/lua/plug.lua'
plugin_home = config_home .. '/plugged'

prequire = function (...)
  local status, mod = pcall(require, ...)
  if status then
    return mod
  else
    return nil
  end
end
