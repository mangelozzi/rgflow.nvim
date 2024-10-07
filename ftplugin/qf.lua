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

-- Hide zs_ze char until populating finished and then they are deleted
vim.opt_local.conceallevel = 3
vim.opt_local.concealcursor = "n"

vim.cmd("setlocal " .. get_prefix(qf_settings.relative_number) .. "relativenumber")
vim.cmd("setlocal " .. get_prefix(qf_settings.wrap) .. "wrap")
vim.cmd("setlocal colorcolumn=" .. qf_settings.color_column)

vim.opt.complete = ".,w,b,]"  -- Default auto complete, but exclude unloaded buffers
-- Can vim.opt.'completeopt' to have a better completion experience
-- Refer to init file, and waiting for https://github.com/nvim-lua/completion-nvim/issues/235
vim.opt.completeopt = "menuone,noinsert,noselect"


if qf_settings.disable_edit_alt_file then
    vim.keymap.set({"", "!"}, "<C-^>", "<NOP>", {buffer = true, noremap = true})
    vim.keymap.set({"", "!"}, "<C-S-^>", "<NOP>", {buffer = true, noremap = true})
    vim.keymap.set({"", "!"}, "<C-6>", "<NOP>", {buffer = true, noremap = true})
end
