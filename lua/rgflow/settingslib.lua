-- how nows brown nows cow
-- is the time nows
local M = {}
M.SETTINGS = {}
local UI_GROUP = 0
local colorlib = require("rgflow.colorlib")

-- The start and end of pattern match invisible marker
-- ASCII value 30, hex 1E. Enter it in vim by pressing <C-V> then 030
M.zs_ze = "\30"

M.RgFlowAutoCmdGroup = vim.api.nvim_create_augroup("RgFlowAutoCmdGroup", {clear = true})

-- Default settings
local defaults = {
    -- For some reason --no-messages makes it stop working
    -- seprated by a space
    -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
    cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",

    -- After a search, whether to set incsearch to be the pattern searched for
    incsearch_after = true,

    -- ui_top_line_char = "▄",
    --  Example chars: ━━━ ═══ ███  ▀▀▀ ▃▃▃   
    ui_top_line_char = "▃",

    -- The vim `completeopt` for when using autocomplete with the RgFlow UI open
    completeopt = "menuone,noinsert,noselect",

    mappings = {
        trigger = {
            n = {
                ["<leader>rG"] = "open_blank", -- open UI - search pattern = blank
                ["<leader>rg"] = "open_cword", -- open UI - search pattern = <cword>
                ["<leader>rp"] = "open_paste", -- open UI - search pattern = First line of unnamed register as the search pattern
                ["<leader>ra"] = "open_again", -- open UI - search pattern = Previous search pattern
                ["<leader>rx"] = "abort",      -- close UI / abort searching / abortadding results
                ["<leader>rc"] = "print_cmd",  -- Print a version of last run rip grep that can be pasted into a shell
            },
            x = {
                ["<leader>rg"] = "open_visual", -- open UI - search pattern = current visual selection
            },
        },
        ui = {
            n = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters
                ["<ESC>"] = "close", -- With the ui open, disgard and close the UI window
                ["?"]     = "show_rg_help", -- Show the rg help in a floating window
                ["<BS>"]  = "nop",   -- No operation
                ["<C-^>"] = "nop",   -- No operation
                ["<C-6>"] = "nop",   -- No operation
            },
            i = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters (from insert mode)
                ["<TAB>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-N>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-P>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
            },
        },
        quickfix = {
            n = {
                ["d"] = "qf_delete",
                ["dd"] = "qf_delete_line",
                ["<TAB>"] = "qf_mark",
                ["<S-TAB>"] = "qf_unmark",
                ["<BS>"]  = "nop", -- No operation
                ["<C-^>"] = "nop", -- No operation
                ["<C-6>"] = "nop", -- No operation
            },
            x = {
                ["d"] = "qf_delete_visual",
                ["<TAB>"] = "qf_mark_visual",
                ["<S-TAB>"] = "qf_unmark_visual",
            }
        },
    },

    quickfix = {
        -- Whether to use `set relativenumber`
        -- Quickfix window - Whether to show relative numbers
        relative_number = false,

        -- Quickfix window - Whether to wrap text
        wrap = false,

        -- Quickfix window - Blank string to not show color_column, or column number to set it at a certain width
        color_column = "",

        -- String to prepend when marking an entry in the quick fix
        mark_str = "▌",

        -- Open the quickfix window automatically after a serach
        open_qf_list = true,

        -- The QF window is set to the height of the number of matches, but bounded
        -- to be between a min of 3 and a max of this variable:
        max_height_lines = 7,

        -- By default a new search will create a search list after the current qf list
        -- Any lists afterwards will be lost
        -- Set to true such that if you navigate to older qf list with :colder, then
        -- starting a new list will append it after :clast
        new_list_always_appended = false,

        -- Disable CTRL+^ and CTRL + SHIFT + ^ to jump to alt file
        -- Generally don't wish to switch to an alt file within the small QF window
        disable_edit_alt_file = true,
    },

    colors = {
        -- The values map to vim.api.nvim_set_hl {val} parameters, see :h nvim_set_hl
        -- Examples:
        --      RgFlowInputPath    = {fg = "fg", bg="#1234FF", bold=true}
        --      RgFlowInputPattern = {link = "Title"}
        ---- UI
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowHead          = nil,
        RgFlowHeadLine      = nil,
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = nil,
        RgFlowInputFlags    = nil,
        RgFlowInputPattern  = nil,
        RgFlowInputPath     = nil,
        ---- Quickfix
        RgFlowQfPattern     = nil,
    },
}

local func_name_to_keymap_opts = {
    open_again       = { noremap = true, silent = true },
    open_blank       = { noremap = true, silent = true },
    open_cword       = { noremap = true, silent = true },
    open_paste       = { noremap = true, silent = true },
    open_visual      = { noremap = true, silent = true },
    abort            = { noremap = true, silent = true },
    print_cmd        = { noremap = true, silent = true },

    auto_complete    = { noremap = true, silent = true, buffer = true, expr = true },
    start            = { noremap = true, silent = true, buffer = true },
    close            = { noremap = true, silent = true, buffer = true },
    show_rg_help     = { noremap = true, silent = true, buffer = true },
    nop              = { noremap = true, silent = true, buffer = true },

    qf_delete        = { noremap = true, silent = true, buffer = true },
    qf_delete_line   = { noremap = true, silent = true, buffer = true },
    qf_delete_visual = { noremap = true, silent = true, buffer = true },
    qf_mark          = { noremap = true, silent = true, buffer = true },
    qf_mark_visual   = { noremap = true, silent = true, buffer = true },
    qf_unmark        = { noremap = true, silent = true, buffer = true },
    qf_unmark_visual = { noremap = true, silent = true, buffer = true },
}

local function get_default_colors()
    local is_ui_light = colorlib.get_is_normal_fg_bright()
    -- local STATE = require('rgflow.state').get_state()
    return {
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowQfPattern     = { bg=colorlib.get_group_bg(0, 'QuickFixLine'), fg=colorlib.get_matches_color(not is_ui_light), bold=true},
        RgFlowHead          = { fg="fg", bg="bg"},
        RgFlowHeadLine      = { bg="bg", fg=colorlib.get_group_bg(0, 'StatusLine')},
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = { bg="fg", fg="bg"},
        RgFlowInputFlags    = { bg="fg", fg="bg"},
        RgFlowInputPattern  = { bg="fg", fg=colorlib.get_pattern_color(is_ui_light), bold=true},
        RgFlowInputPath     = { bg="fg", fg=(is_ui_light and '#333333' or '#eeeeee')},
    }
end

local function apply_color_def(group_name, color_def)
    vim.api.nvim_set_hl(UI_GROUP, group_name, color_def)
end

local function setup_hi_groups(user_colors)
    local default_colors = get_default_colors()
    for group_name, default_def in pairs(default_colors) do
        local user_def = user_colors[group_name]
        if user_def then
            -- If user defines a color, always apply it
            apply_color_def(group_name, user_def)
        else
            if not colorlib.get_hi_group_exists(UI_GROUP, group_name) then
                apply_color_def(group_name, default_def)
            end
        end
    end
end

function M.apply_keymaps(mappings)
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

function M.setup(user_settings)
    local STATE = require("rgflow.state").get_state()
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
