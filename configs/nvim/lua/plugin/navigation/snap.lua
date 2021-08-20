local bindings = require('lib/bindings')
local registry = require('lib/registry')

registry.install {
  'camspiers/snap',
  skip = true,
  defer_first = function ()
    bindings.map.normal('<C-p>', function ()
      local snap = require('snap')
      snap.run({
        reverse = true,
        producer = snap.get('consumer.fzf')(
          snap.get('consumer.try')(
            snap.get('producer.ripgrep.file').hidden,
            snap.get('producer.git.file'),
            snap.get('producer.fd.file').hidden,
            snap.get('producer.luv.file')
          )
        ),
        select = snap.get('select.file').select,
        multiselect = snap.get('select.file').multiselect,
        views = { snap.get('preview.file') }
      })
    end)
    bindings.map.normal('<leader>/', function ()
      local snap = require('snap')
      snap.run({
        reverse = true,
        producer = snap.get('consumer.fzf')(snap.get('producer.vim.currentbuffer')),
        select = snap.get('select.currentbuffer').select
      })
    end)
    bindings.map.normal('<leader>f', function ()
      local snap = require('snap')

      snap.run({
        reverse = true,
        producer = snap.get('producer.ripgrep.vimgrep').line({ '--hidden' }),
        prompt = 'Rg>',
        steps = {
          {
            consumer = snap.get('consumer.fzf'),
            config = { prompt = 'FZF>' }
          }
        },
        select = snap.get('select.vimgrep').select,
        multiselect = snap.get('select.vimgrep').multiselect,
        views = { snap.get('preview.vimgrep') }
      })
    end)
  end
}
