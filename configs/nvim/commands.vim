" Kill the annoyance
command! -bang Q quit<bang>
command! -bang Qa quitall<bang>
command! -bang QA quitall<bang>

" Write read-only file with sudo
command! WS w !sudo tee %

" fzf command improvements
command! -bang -nargs=* Files
  \ call fzf#vim#files(0,
  \   <bang>0 ? fzf#vim#with_preview({ 'options': ['--layout=reverse'], 'window': { 'width': 1, 'height': 0.4, 'yoffset': 1 }})
  \           : fzf#vim#with_preview()
  \ )

command! -bang -nargs=* BLines
  \ call fzf#vim#buffer_lines('',
  \   <bang>0 ? { 'options': ['--layout=reverse'], 'window': { 'width': 1, 'height': 0.4, 'yoffset': 1 }}
  \           : {}
  \ )

" Rg command tweaks to search only file content
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..', 'window': { 'width': 1, 'height': 0.4, 'yoffset': 1 }})
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'})
  \   )

function! RipgrepFzf(query, inline)
  let command_fmt = 'rg --column --line-number --hidden --smart-case --no-heading --color=always -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  if a:inline
    let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command], 'window': { 'width': 1, 'height': 0.4, 'yoffset': 1 }}
  else
    let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  endif
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec))
endfunction

command! -bang -nargs=* RG call RipgrepFzf(<q-args>, <bang>0)
