local get_settings = require("rgflow.settingslib").get_settings
local qf_settings = get_settings().quickfix
local rgflow = require("rgflow")

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

local function qf_apply_mappings()
    local mappings = get_settings().quickfix.mappings
    for mode, mode_mappings in pairs(mappings) do
        for keymap, func_name in pairs(mode_mappings) do
            vim.keymap.set(mode, keymap, require("rgflow")[func_name], {noremap = true, buffer = true, silent = true})
        end
    end
end

qf_apply_mappings()
