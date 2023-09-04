if vim.bo.filetype ~= 'qf' then
    -- filetype check for when debugging & sourcing
    return
end

local settings = require("rgflow.settingslib")
local qf_settings = settings.get_settings().quickfix
local rgflow = require("rgflow")

local mappings = settings.get_settings().mappings.quickfix
settings.apply_keymaps(mappings)

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

vim.opt.complete = ".,w,b,]"  -- Default auto complete, but exclude unloaded buffers
-- Can vim.opt.'completeopt' to have a better completion experience
-- Refer to init file, and waiting for https://github.com/nvim-lua/completion-nvim/issues/235
vim.opt.completeopt = "menuone,noinsert,noselect"


if qf_settings.disable_edit_alt_file then
    vim.keymap.set({"", "!"}, "<C-^>", "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-S-^>", "<NOP>", {noremap = true})
    vim.keymap.set({"", "!"}, "<C-6>", "<NOP>", {noremap = true})
end
