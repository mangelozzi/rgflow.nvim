if vim.bo.filetype ~= "rgflow" then
    -- filetype check for when debugging & sourcing
    return
end

local settingslib = require("rgflow.settingslib")
local SETTINGS = settingslib.get_settings()
local max_input_lines = 3

-- Gobal variable so completefunc can be set to "v:lua.RGFLOW_FLAGS_COMPLETE"
RGFLOW_FLAGS_COMPLETE = require("rgflow.autocomplete").rg_flags_complete
vim.opt_local.omnifunc = "v:lua.RGFLOW_FLAGS_COMPLETE"
vim.opt_local.completeopt = SETTINGS.completeopt

local options = {noremap = true, buffer = true, silent = true}
settingslib.apply_keymaps(SETTINGS.mappings.ui, options)

-- If one leaves the window then returns, these groups look wacky if not fixed
vim.opt_local.winhighlight = "EndOfBuffer:RgFlowInputBg,CursorLine:RgFlowInputBg,NormalFloat:RgFlowInputBg"

-- If have excess lines, J always works, else only disable it
vim.keymap.set(
    "n",
    "J",
    function()
        if vim.fn.line("$") > max_input_lines then
            return "J"
        else
            return ""
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true}
)

-- If have excess lines, dd always works, else only delete inner line text
vim.keymap.set(
    "n",
    "dd",
    function()
        if vim.fn.line("$") > max_input_lines then
            return "dd"
        else
            return "0d$"
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true, nowait = true}
)

-- If have excess lines, <DEL> always works, else only works when when cursor is not at the line end (prevents line joining)
vim.keymap.set(
    "i",
    "<DEL>",
    function()
        if vim.fn.line("$") > max_input_lines then
            return "<DEL>"
        else
            if vim.fn.col(".") ~= vim.fn.col("$") then
                return "<DEL>"
            else
                return ""
            end
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true}
)

-- If have excess lines, <BS> always works, else only works when when cursor is not at the line start (prevents line joining)
vim.keymap.set(
    "i",
    "<BS>",
    function()
        if vim.fn.line("$") > max_input_lines then
            return "<BS>"
        else
            if vim.fn.col(".") ~= 1 then
                return "<BS>"
            else
                return ""
            end
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true}
)

-- Disable o unless don't have enough lines
vim.keymap.set(
    "n",
    "o",
    function()
        if vim.fn.line("$") < max_input_lines then
            return "o"
        else
            return ""
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true}
)

-- Disable O unless don't have enough lines
vim.keymap.set(
    "n",
    "O",
    function()
        if vim.fn.line("$") < max_input_lines then
            return "O"
        else
            return ""
        end
    end,
    {buffer = true, silent = true, expr = true, noremap = true}
)
