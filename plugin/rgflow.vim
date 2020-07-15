" nvim-rgflow.lua Plugin

" Testing variable ensures the module and settings are reloaded when ever
" the affected files are sourced.
let testing = 1

" When not testing, dont use cached setup
if exists('g:loaded_rgflow') && !testing
    finish
endif

" HILIGHTING GROUPS
if !hlexists('RgFlowQfPattern') || testing
    " Recommend not setting a BG so it uses the current lines BG:
    hi RgFlowQfPattern    guifg=#A0FFA0 guibg=none gui=bold ctermfg=15 ctermbg=none cterm=bold
endif
if !hlexists('RgFlowHead') || testing
    hi RgFlowHead         guifg=white   guibg=black gui=bold ctermfg=15 ctermbg=0, cterm=bold
endif
if !hlexists('RgFlowHeadLine') || testing
    hi RgFlowHeadLine     guifg=#00CC00 guibg=black gui=bold ctermfg=15 ctermbg=0, cterm=bold
endif
if !hlexists('RgFlowInputBg') || testing
    " Even though just a background, add the foreground or else when
    " appending cant see the insert cursor
    hi RgFlowInputBg      guifg=black   guibg=white ctermfg=0 ctermbg=15
endif
if !hlexists('RgFlowInputFlags') || testing
    hi RgFlowInputFlags   guifg=gray    guibg=white ctermfg=8 ctermbg=15
endif
if !hlexists('RgFlowInputPattern') || testing
    hi RgFlowInputPattern guifg=green   guibg=white gui=bold ctermfg=2 ctermbg=15 cterm=bold
endif
if !hlexists('RgFlowInputPath') || testing
    hi RgFlowInputPath    guifg=black   guibg=white ctermfg=0 ctermbg=15
endif

" DEFAULT SETTINGS
if testing
    " When testing, wish to reload lua files, and reset global values
    let g:rgflow_search_keymaps = 1
    let g:rgflow_qf_keymaps = 1
    let g:rgflow_flags = '--smart-case --glob=!spike/*'
    let g:rgflow_set_incsearch = 0
    let g:rgflow_mark_str = "▌"
    let g:rgflow_open_qf_list = 1
else
    " Applied only if not already set

    " Use default keymap to start rgflow search
    let g:rgflow_search_keymaps = get(g:, 'rgflow_search_keymaps', 1)

    " Use default keymaps with the quickfix window (used in ftplugin/qf.vim)
    let g:rgflow_qf_keymaps = get(g:, 'rgflow_qf_keymaps', 1)

    " For some reason --no-messages makes it stop working
    let g:rgflow_flags = get(g:, 'rgflow_flags', '--smart-case --glob=!spike/*')

    " After a search, whether to set incsearch to be the pattern searched for
    let g:rgflow_set_incsearch = get(g:, 'rgflow_set_incsearch', 1)

    " String to prepend when marking an entry in the quick fix
    let g:rgflow_mark_str = get(g:, 'rgflow_mark_str', '▌')

    " Open the quickfix window automatically after a serach
    let g:rgflow_open_qf_list = get(g:, 'rgflow_open_qf_list', 1)
endif

" SOURCE MODULE
if testing
    if has('unix')
        lua rgflow = dofile("/home/michael/.config/nvim/nvim-rgflow.lua/lua/rgflow.lua")
    else
        lua rgflow = dofile("C:/Users/Michael/.config/nvim/nvim-rgflow.lua/lua/rgflow.lua")
    endif
else
    lua rgflow = require('rgflow')
endif

" PLUG COMMANDS
" Map functions to commands, for easy mapping to hot keys
nnoremap <Plug>RgflowDeleteQuickfix       :<C-U>set  opfunc=v:lua.rgflow.qf_del_operator<CR>g@
nnoremap <Plug>RgflowDeleteQuickfixLine   :<C-U>call v:lua.rgflow.qf_del_operator('line')<CR>
vnoremap <Plug>RgflowDeleteQuickfixVisual :<C-U>call v:lua.rgflow.qf_del_operator(visualmode())<CR>
nnoremap <Plug>RgflowMarkQuickfixLine     :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, 'line')<CR>
vnoremap <Plug>RgflowMarkQuickfixVisual   :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, visualmode())<CR>
nnoremap <Plug>RgflowUnmarkQuickfixLine   :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, 'line')<CR>
vnoremap <Plug>RgflowUnmarkQuickfixVisual :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, visualmode())<CR>

if g:rgflow_search_keymaps
    " KEY MAPPINGS
    " Rip grep in files, use <cword> under the cursor as starting point
    nnoremap <leader>rg :<C-U>lua rgflow.start_via_hotkey('n')<CR>
    " Rip grep in files, use visual selection as starting point
    xnoremap <leader>rg :<C-U>call v:lua.rgflow.start_via_hotkey(visualmode())<Cr>
endif

let g:loaded_rgflow = 1
