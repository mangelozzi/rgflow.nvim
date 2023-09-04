if vim.bo.filetype ~= "rgflow" then
    -- filetype check for when debugging & sourcing
    return
end

local settingslib = require("rgflow.settingslib")
local SETTINGS = settingslib.get_settings()

-- Gobal variable so completefunc can be set to "v:lua.RGFLOW_FLAGS_COMPLETE"
RGFLOW_FLAGS_COMPLETE = require("rgflow.autocomplete").rg_flags_complete
vim.opt_local.omnifunc = "v:lua.RGFLOW_FLAGS_COMPLETE"
vim.opt_local.completeopt = SETTINGS.completeopt

local options = {noremap = true, buffer = true, silent = true}
settingslib.apply_keymaps(SETTINGS.mappings.ui, options)

-- If one leaves the window then returns, these groups look wacky if not fixed
vim.opt_local.winhighlight = "EndOfBuffer:RgFlowInputBg,CursorLine:RgFlowInputBg,NormalFloat:RgFlowInputBg"
