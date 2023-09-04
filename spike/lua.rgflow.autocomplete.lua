-- FLIPPIN NEOVIM BUG:
-- Setting completefunc to `v:lua.require('foo').bar` always receives `findstart` and `base` as `nil`
-- Have to create a global lua object, and use it as `v:lua.GLOBAL_FUNC`
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.require('rgflow.autocomplete').rg_flags_complete")
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.RG_FLAGS_COMPLETE")

-- RG_FLAGS_COMPLETE = rg_flags_complete
-- vim.cmd("messages clear")
-- vim.print(rg_flags_complete(1, ' --sm'))
-- vim.cmd("mess")

--- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete(findstart, base)
    print('Auto_complete>>', 'findstart', findstart, 'base', base)
    local linenr = api.nvim_win_get_cursor(0)[1]
    if linenr == 1 then
        return rg_flags_complete(findstart, base)
    elseif linenr == 2 then
        return rg_flags_complete(findstart, base)
    elseif linenr == 3 then
        return require('cmp').complete_items(findstart, base)
    end
end


-- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete()
    if vim.fn.pumvisible() ~= 0 then
        -- If pop up menu is no hidden, i.e. shown
        return
    end
    local linenr = api.nvim_win_get_cursor(0)[1]
    if linenr == 1 then
        -- Flags line - Using completefunc
        -- nvim_buf_set_option({buffer}, {name}, {value})
        -- api.nvim_buf_set_option(0, "completefunc", rg.flags_complete)
        -- api.nvim_set_option_value("completefunc", "v:lua:rgflow.rg.flags_complete", {scope="local"})
        print('set complete func')
        vim.opt_local.completefunc = "v:lua.require('rgflow.rg').flags_complete"
        -- api.nvim_input("<C-X><C-U>")
        -- print('feeding keys')
        -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-X><C-U>',true,nil,true), "n")
    elseif linenr == 2 then
        -- Pattern line
        -- Default autocomplete is an empty string
        vim.opt_local.completefunc = ""
        -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-N>',true,nil,true), "n")
    elseif linenr == 3 then
        -- Filename line
        vim.opt_local.completefunc = "file"
        -- vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-X><C-F>',true,nil,true), "n")
    end
    -- Get the completions using the specified completefunc.
    -- local completions = require("cmp").complete(findstart, base, completefunc)

    vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-X><C-U>',true,nil,true), "n")

    -- -- Return the completions.
    -- return completions
end


--- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete2()
    if vim.fn.pumvisible() ~= 0 then
        -- If pop up menu is no hidden, i.e. shown
        return
    end
    local linenr = vim.api.nvim_win_get_cursor(0)[1]
    if linenr == 1 then
        -- Flags line - Using completefunc
        -- nvim_buf_set_option({buffer}, {name}, {value})
        -- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.require('rgflow.autocomplete').rg_flags_complete")
        vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.RG_FLAGS_COMPLETE")
        vim.api.nvim_input("<C-X><C-U>")
    elseif linenr == 2 then
        -- Pattern line
        -- vim.api.nvim_input("<C-N>")
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-N>", true, nil, true), "n")
    elseif linenr == 3 then
        -- Filename line
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-N>", true, nil, true), "n")
        vim.api.nvim_input("<C-X><C-F>")
    end
end


return M
