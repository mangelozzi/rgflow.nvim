if vim.bo.filetype ~= "rgflow" then
    -- filetype check for when debugging & sourcing
    return
end

local settings = require("rgflow.settingslib")

local mappings = settings.get_settings().mappings.ui
local options = {noremap = true, buffer = true, silent = true}
settings.apply_keymaps(mappings, options)

vim.opt_local.omnifunc = "v:lua.require('rgflow.autocomplete').auto_complete"

-- local RgflowGroup = vim.api.nvim_create_augroup("RgflowGroup", {clear = true})
-- vim.api.nvim_create_autocmd(
--     "CursorMovedI",
--     {
--         desc = "When changing between the 3 inputs lines of the ui, set the automcomplete func accordingly",
--         group = RgflowGr:oup,
--         callback = function()
--             local linenr = vim.api.nvim_win_get_cursor(0)[1]
--             if linenr == 1 then
--                 vim.opt_local.completefunc = "v:lua.require('rgflow.rg').flags_complete"
--             elseif linenr == 2 then
--                 vim.opt_local.completefunc = ""
--             elseif linenr == 3 then
--                 vim.opt_local.completefunc = "file"
--             end
--             print(vim.opt_local.completefunc)
--         end
--     }
-- )
--
-- apply_mappings()
