local registry = require('lib/registry')

registry.install('kkoomen/vim-doge', {
  ['do'] = ':call doge#install()',
  on = 'DogeGenerate'
})
