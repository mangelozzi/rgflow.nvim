local get_settings = require('rgflow.settingslib').get_settings
local qf_settings = get_settings().quickfix
local rgflow = require('rgflow')

local function get_prefix(predicate)
    if predicate then
        return ''
    else
        return 'no'
    end
end

vim.cmd('setlocal '..get_prefix(qf_settings.relative_number)..'relativenumber')
vim.cmd('setlocal '..get_prefix(qf_settings.wrap)..'wrap')
vim.cmd('setlocal colorcolumn=' .. qf_settings.color_column)

if qf_settings.disable_edit_alt_file then
    vim.keymap.set({"", "!"}, "<C-^>",   "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-S-^>", "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-6>",   "<NOP>", {noremap = true})
end

-- nnoremap <Plug>RgflowDeleteQuickfix       :<C-U>set  opfunc=v:lua.rgflow.qf_del_operator<CR>g@
-- nnoremap <Plug>RgflowDeleteQuickfixLine   :<C-U>call v:lua.rgflow.qf_del_operator('line')<CR>
-- vnoremap <Plug>RgflowDeleteQuickfixVisual :<C-U>call v:lua.rgflow.qf_del_operator(visualmode())<CR>
-- nnoremap <Plug>RgflowMarkQuickfixLine     :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, 'line')<CR>
-- vnoremap <Plug>RgflowMarkQuickfixVisual   :<C-U>call v:lua.rgflow.qf_mark_operator(v:true, visualmode())<CR>
-- nnoremap <Plug>RgflowUnmarkQuickfixLine   :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, 'line')<CR>
-- vnoremap <Plug>RgflowUnmarkQuickfixVisual :<C-U>call v:lua.rgflow.qf_mark_operator(v:false, visualmode())<CR>

-- vim.keymap.nnoremap {"<expr>", rgflow.qf_delete, "v:lua.rgflow.qf_del_operator()"}

-- vim.keymap.nnoremap {"<expr>", rgflow.qf_delete_line, "v:lua.rgflow.qf_del_operator('line')"}
-- vim.keymap.vnoremap {"<expr>", rgflow.qf_delete_visual, "v:lua.rgflow.qf_del_operator(visualmode())"}
-- vim.keymap.nnoremap {"<expr>", rgflow.mark_quickfix_line, "v:lua.rgflow.qf_mark_operator(true, 'line')"}
-- vim.keymap.vnoremap {"<expr>", rgflow.mark_quickfix_visual, "v:lua.rgflow.qf_mark_operator(true, visualmode())"}
-- vim.keymap.nnoremap {"<expr>", rgflow.unmark_quickfix_line, "v:lua.rgflow.qf_mark_operator(false, 'line')"}
-- vim.keymap.vnoremap {"<expr>", rgflow.unmark_quickfix_visual, "v:lua.rgflow.qf_mark_operator(false, visualmode())"}

local function qf_apply_mappings()
    local mappings = get_settings().mappings
    for mode, mode_mappings in pairs(mappings) do
        for keymap, func_name in pairs(mode_mappings) do
            if (func_name == 'delete') then
                print("TODO delete opeartor")
                -- func = function() 
                --     vim.fn.feedkeys("<C-U>")
                --     require('rgflow').qf_del_operator(vim.fn.visualmode())
                --     , {noremap = true, buffer = true}
                --
                -- vim.keymap.set(mode, 
                -- end
                -- )
            else
                print('keymap QF', mode, keymap, func_name)
                vim.keymap.set(mode, keymap, require('rgflow')[func_name], {noremap = true, buffer= true})
            end
        end
    end
end

qf_apply_mappings()
