-- common constants
api = vim.api
env = vim.env
fn = vim.fn
luv = vim.loop

vim_plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
config_home = fn.stdpath('config')

lua_home = config_home .. '/lua'
vim_plug_path = config_home .. '/autoload/plug.vim'
plugin_home = config_home .. '/plugged'
