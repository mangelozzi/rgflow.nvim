if vim.bo.filetype ~= 'qf' then
    -- filetype check for when debugging & sourcing
    return
end

local settings = require("rgflow.settingslib")
local qf_settings = settings.get_settings().quickfix
local rgflow = require("rgflow")

local mappings = settings.get_settings().mappings.quickfix
local options = {noremap = true, buffer = true, silent = true}
settings.apply_keymaps(mappings, options)

local function get_prefix(predicate)
    if predicate then
        return ""
    else
        return "no"
    end
end

vim.cmd("setlocal " .. get_prefix(qf_settings.relative_number) .. "relativenumber")
vim.cmd("setlocal " .. get_prefix(qf_settings.wrap) .. "wrap")
vim.cmd("setlocal colorcolumn=" .. qf_settings.color_column)

if qf_settings.disable_edit_alt_file then
    vim.keymap.set({"", "!"}, "<C-^>", "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-S-^>", "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-6>", "<NOP>", {noremap = true})
end
