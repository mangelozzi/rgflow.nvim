if vim.bo.filetype ~= "rgflow" then
    -- filetype check for when debugging & sourcing
    return
end

-- Gobal variable so completefunc can be set to "v:lua.RGFLOW_FLAGS_COMPLETE"
RGFLOW_FLAGS_COMPLETE = require("rgflow.autocomplete").rg_flags_complete
vim.opt_local.omnifunc = "v:lua.RGFLOW_FLAGS_COMPLETE"

local settings = require("rgflow.settingslib")

local mappings = settings.get_settings().mappings.ui
local options = {noremap = true, buffer = true, silent = true}
settings.apply_keymaps(mappings, options)
