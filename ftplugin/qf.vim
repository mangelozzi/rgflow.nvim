" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal nowrap
setlocal norelativenumber
setlocal colorcolumn=

" conceal options are always window local
set conceallevel=2
set concealcursor=nvic

if g:rgflow_qf_keymaps
    "Disable accidental alternate buffer switching in quickfix window
    nnoremap <buffer> <C-^>   <Nop>
    nnoremap <buffer> <C-S-^> <Nop>
    nnoremap <buffer> <C-6>   <Nop>

    nmap <silent> <buffer> d        <Plug>RgflowDeleteQuickfix
    nmap <silent> <buffer> dd       <Plug>RgflowDeleteQuickfixLine
    vmap <silent> <buffer> d        <Plug>RgflowDeleteQuickfixVisual

    nmap <silent> <buffer> <Tab>    <Plug>RgflowMarkQuickfixLine
    vmap <silent> <buffer> <Tab>    <Plug>RgflowMarkQuickfixVisual
    nmap <silent> <buffer> <S-Tab>  <Plug>RgflowUnmarkQuickfixLine
    vmap <silent> <buffer> <S-Tab>  <Plug>RgflowUnmarkQuickfixVisual
endif

" Needs to be called whenever quickfix window is opened
" :cclose will clear the following highlighting
lua rgflow.hl_qf_matches()

