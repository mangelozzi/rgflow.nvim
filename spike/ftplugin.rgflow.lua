vim.api.nvim_create_autocmd(
    "CursorMovedI",
    {
        desc = "When changing between the 3 inputs lines of the ui, set the automcomplete func accordingly",
        group = settings.RgFlowAutoCmdGroup,
        callback = function()
            local linenr = vim.api.nvim_win_get_cursor(0)[1]
            if linenr == 1 then
                -- vim.opt_local.completefunc = "v:lua.require('rgflow.rg').flags_complete"
                vim.opt_local.completefunc = "v:lua.RGFLOW_AUTO_COMPLETE"
            elseif linenr == 2 then
                vim.opt_local.completefunc = ""
            elseif linenr == 3 then
                vim.opt_local.completefunc = "file"
            end
            -- print(vim.opt_local.completefunc)
        end
    }
)


-- vim.opt_local.completefunc = "v:lua.require('rgflow.autocomplete').auto_complete" -- DOES NOT WORK, args always 0 for base start
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.RG_FLAGS_COMPLETE")
