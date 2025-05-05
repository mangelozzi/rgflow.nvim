-- how nows brown nows cow
-- is the time nows
local M = {}
M.SETTINGS = {}
local UI_GROUP = 0

-- The start and end of pattern match invisible marker
-- ASCII value 30, hex 1E. Enter it in vim by pressing <C-V> then 030
M.zs_ze = "\030"

M.RgFlowAutoCmdGroup = vim.api.nvim_create_augroup("RgFlowAutoCmdGroup", {clear = true})

local func_name_to_keymap_opts = {

    open_again       = { noremap = true, silent = true, desc = "Rgflow open previous" },
    open_blank       = { noremap = true, silent = true, desc = "Rgflow open blank" },
    open_paste       = { noremap = true, silent = true, desc = "Rgflow open unnamed" },
    open_cword       = { noremap = true, silent = true, desc = "Rgflow open <cword>" },
    open_cword_path  = { noremap = true, silent = true, desc = "Rgflow open <cword> path=%:h" },
    open_visual      = { noremap = true, silent = true, desc = "Rgflow open visual" },
    abort            = { noremap = true, silent = true, desc = "Rgflow abort" },
    print_cmd        = { noremap = true, silent = true, desc = "Rgflow print command" },
    print_status     = { noremap = true, silent = true, desc = "Rgflow print status" },

    auto_complete    = { noremap = true, silent = true, buffer = true, expr = true, desc = "Rgflow autocomplete" },
    start            = { noremap = true, silent = true, buffer = true, desc = "Rgflow start" },
    close            = { noremap = true, silent = true, buffer = true, desc = "Rgflow close" },
    show_rg_help     = { noremap = true, silent = true, buffer = true, desc = "Rgflow help" },
    parent_path      = { noremap = true, silent = true, buffer = true, desc = "Rgflow parent path" },
    nop              = { noremap = true, silent = true, buffer = true, desc = "Rgflow nop" },

    qf_delete        = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF del" },
    qf_delete_line   = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF del line" },
    qf_delete_visual = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF vis del" },
    qf_mark          = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF mark" },
    qf_mark_visual   = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF vis mark" },
    qf_unmark        = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF unmark" },
    qf_unmark_visual = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF vis unmark" },
    cfilter          = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF :Cfilter", nowait = true },
    cfilterbang      = { noremap = true, silent = true, buffer = true, desc = "Rgflow QF :Cfilter!" },
}

local function get_default_colors()
    return {
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowQfPattern     = { link='Number' },
        RgFlowHead          = { link='FloatFooter' },
        RgFlowHeadLine      = { link='FloatBorder' },
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = { link='NormalFloat' },
        RgFlowInputFlags    = { link='NormalFloat' },
        RgFlowInputPattern  = { link='Constant' },
        RgFlowInputPath     = { link='NormalFloat' },
    }
end

local function apply_color_def(group_name, color_def)
    vim.api.nvim_set_hl(UI_GROUP, group_name, color_def)
end

local function get_hi_group_exists(ns_id, name)
    local group_info = vim.api.nvim_get_hl(ns_id, {name = name})
    -- next will return nil if an empty dict, else a value
    return next(group_info)
end

local function setup_hi_groups(user_colors)
    local default_colors = get_default_colors()
    for group_name, default_def in pairs(default_colors) do
        local user_def = user_colors[group_name]
        if user_def then
            -- If user defines a color, always apply it
            apply_color_def(group_name, user_def)
        else
            if not get_hi_group_exists(UI_GROUP, group_name) then
                apply_color_def(group_name, default_def)
            end
        end
    end
end

function M.apply_keymaps(mappings)
    if not mappings then
        -- If not mappings to be applied
        return
    end
    for mode, mode_mappings in pairs(mappings) do
        for keymap, func_name in pairs(mode_mappings) do
            local options = func_name_to_keymap_opts[func_name]
            if func_name == "start" and mode == "i" then
                -- If the pum and press say ENTER to start a search,
                -- it should select the PUM entry (not start a search)
                vim.keymap.set(
                    mode,
                    keymap,
                    function()
                        if vim.fn.pumvisible() == 0 then
                            require("rgflow")[func_name]()
                        else
                            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, nil, true), "n")
                        end
                    end,
                    options
                )
            else
                vim.keymap.set(mode, keymap, require("rgflow")[func_name], options)
            end
        end
    end
end

local function apply_settings(settings)
    setup_hi_groups(settings.colors)
    M.apply_keymaps(settings.mappings.trigger)
    M.SETTINGS = settings
end

local function create_sync_colors_autocmd()
    -- Some color schemes unlink all colors, relink them each time
    vim.api.nvim_create_autocmd(
        "ColorScheme",
        {
            desc = "When changing colorscheme re-calculate the colors",
            group = M.RgFlowAutoCmdGroup,
            callback = function()
                local STATE = require("rgflow.state").get_state()
                setup_hi_groups(STATE.applied_settings.colors)
            end
        }
    )
end

local function handle_disable_mappings(user_settings, defaults, settings_key, mapping_key)
    local enable
    if user_settings[settings_key] == nil then
        enable = defaults[settings_key]
    else
        enable = user_settings[settings_key]
    end
    if not enable then
        defaults.mappings[mapping_key] = nil
    end
end

function M.setup(user_settings)
    local STATE = require("rgflow.state").get_state()
    local defaults = require('rgflow.defaults')
    handle_disable_mappings(user_settings, defaults, 'default_trigger_mappings', 'trigger')
    handle_disable_mappings(user_settings, defaults, 'default_ui_mappings', 'ui')
    handle_disable_mappings(user_settings, defaults, 'default_quickfix_mappings', 'quickfix')
    local settings = vim.tbl_deep_extend("force", defaults, user_settings)
    apply_settings(settings)
    STATE.applied_settings = settings
    create_sync_colors_autocmd()
end

-- Provide a getter function to access the settings
-- The table may change or be reassigned, and hence modules that import it will
-- loose their reference to the current settings
function M.get_settings()
    return M.SETTINGS
end

return M
