if vim.bo.filetype ~= "rgflow" then
    -- filetype check for when debugging & sourcing
    return
end

local settings = require("rgflow.settingslib")

local mappings = settings.get_settings().mappings.ui
local options = {noremap = true, buffer = true, silent = true}
settings.apply_keymaps(mappings, options)

-- vim.opt_local.completefunc = "v:lua.require('rgflow.autocomplete').auto_complete"
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.RG_FLAGS_COMPLETE")
