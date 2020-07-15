" Map <CR> to start search in normal mode
nnoremap <buffer> <CR> <cmd>lua rgflow.search()<CR>

" Map various abort like keys to cancel search
noremap <buffer> <ESC> <cmd>lua rgflow.abort()<CR>
noremap <buffer> <C-]> <cmd>lua rgflow.abort()<CR>
noremap <buffer> <C-C> <cmd>lua rgflow.abort()<CR>

" Map tab to be general autocomplete flags/buffer/file depending on which line user is on
inoremap <buffer> <TAB> <cmd>lua rgflow.complete()<CR>

" The following mappings are convience when working with the input dialogue,
" to make it easier to work with the 3 lines of input

" If pop up menu visible, map <CR> to select autocomplete option, else if
" there are not enough lines <CR> works, else map to <DOWN>
" <CR> is used within mapping, so must be none recursive.
inoremap <buffer> <expr> <CR> (pumvisible() ? '<C-Y>' : (line('$') < 3 ? '<CR>' : '<DOWN>'))

" Disable alternate buffer (because can't switch back afterwards)
nnoremap <buffer> <C-^>   <NOP>
nnoremap <buffer> <C-S-^> <NOP>
nnoremap <buffer> <C-6>   <NOP>

" If have excess lines, J always works, else only disable it
noremap <buffer> <expr> J (line('$') > 3 ? 'J' : '')

" If have excess lines, <DEL> always works, else only works when when cursor is not at the line end (prevents line joining)
inoremap <buffer> <expr> <DEL> (line('$') > 3 ? '<DEL>' : (col('.') != col('$') ? '<DEL>' : ''))

" If have excess lines, <BS> always works, else only works when when cursor is not at the line start (prevents line joining)
inoremap <buffer> <expr> <BS>  (line('$') > 3 ? '<BS>' : (col('.') != 1 ? '<BS>' : ''))

" If have excess lines, dd always works, else only delete inner line text
noremap <buffer> <nowait> <expr> dd (line('$') > 3 ? 'dd' : '0d$')
