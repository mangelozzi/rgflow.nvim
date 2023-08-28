-- Map functions to commands, for easy mapping to hot keys
vim.cmd("nnoremap <Plug>DeleteQuickfix       :<C-U>set  opfunc=v:lua.rgflow.qf_del_operator<CR>g@")
vim.cmd("nnoremap <Plug>DeleteQuickfixLine   :<C-U>call v:lua.rgflow.qf_del_operator('line')<CR>")
vim.cmd("vnoremap <Plug>DeleteQuickfixVisual :<C-U>call v:lua.rgflow.qf_del_operator(visualmode())<CR>")
vim.cmd("nnoremap <Plug>MarkQuickfixLine     :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, 'line')<CR>")
vim.cmd("vnoremap <Plug>MarkQuickfixVisual   :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, visualmode())<CR>")
vim.cmd("nnoremap <Plug>UnmarkQuickfixLine   :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, 'line')<CR>")
vim.cmd("vnoremap <Plug>UnmarkQuickfixVisual :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, visualmode())<CR>")

-- vim.cmd("nnoremap <Plug>Search <cmd>lua required:<C-U>call v:lua.rgflow.qf_mark_operator(v:false, visualmode())<CR>")

-- " KEY MAPPINGS
-- " Rip grep in files, use <cword> under the cursor as starting point
-- nnoremap <leader>rg :<C-U>lua rgflow.start_via_hotkey('n')<CR>
-- " Start and paste contents of search register
-- nnoremap <leader>rr :<C-U>lua rgflow.start_via_hotkey('n')<CR>0D"/p
-- " Rip grep in files, use visual selection as starting point
-- xnoremap <leader>rg :<C-U>call v:lua.rgflow.start_via_hotkey(visualmode())<Cr>
