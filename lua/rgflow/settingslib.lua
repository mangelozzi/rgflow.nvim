local M = {}
M.SETTINGS = {}

-- Default settings
local defaults = {
    -- For some reason --no-messages makes it stop working
    -- seprated by a space
    -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
    cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",
    -- After a search, whether to set incsearch to be the pattern searched for
    incsearch_after = true,
    mappings = {
        n = {
            ["<CR>"] = "start", -- With the ui open, start a search with the current parameters
            ["<ESC>"] = "close", -- With the ui open, disgard and close the UI window
            ["<leader>rG"] = "open_blank", -- open UI - search pattern = blank
            ["<leader>rg"] = "open_cword", -- open UI - search pattern = <cword>
            ["<leader>rp"] = "open_paste", -- open UI - search pattern = First line of unnamed register as the search pattern
            ["<leader>ra"] = "open_again" -- open UI - search pattern = Previous search pattern
        },
        i = {
            ["<CR>"] = "start" -- With the ui open, start a search with the current parameters (from insert mode)
        },
        x = {
            ["<leader>rg"] = "open_visual" -- open UI - search pattern = current visual selection
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

        -- The start and end of pattern match invisible marker
        zs_ze_pattern_delimiter = "\30",

        -- Open the quickfix window automatically after a serach
        open_qf_list = true,

        -- The QF window is set to the height of the number of matches, but bounded
        -- to be between a min of 3 and a max of this variable:
        max_height_lines = 7,

        -- Disable CTRL+^ and CTRL + SHIFT + ^ to jump to alt file
        -- Generally don't wish to switch to an alt file within the small QF window
        disable_edit_alt_file = true,
        mappings = {
            n = {
                ["d"] = "qf_delete",
                ["dd"] = "qf_delete_line",
                ["<TAB>"] = "qf_mark",
                ["<S-TAB>"] = "qf_unmark",
            },
            x = {
                ["d"] = "qf_delete_visual",
                ["<TAB>"] = "qf_mark_visual",
                ["<S-TAB>"] = "qf_unmark_visual",
            },
        },
    },
    colors = {
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowQfPattern     = "guifg=#A0FFA0 guibg=none gui=bold ctermfg=15 ctermbg=none cterm=bold",
        RgFlowHead          = "guifg=white   guibg=black gui=bold ctermfg=15 ctermbg=0, cterm=bold",
        RgFlowHeadLine      = "guifg=#00CC00 guibg=black gui=bold ctermfg=15 ctermbg=0, cterm=bold",
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = "guifg=black   guibg=#e0e0e0 ctermfg=0 ctermbg=254",
        RgFlowInputFlags    = "guifg=gray    guibg=#e0e0e0 ctermfg=8 ctermbg=254",
        RgFlowInputPattern  = "guifg=green   guibg=#e0e0e0 gui=bold ctermfg=2 ctermbg=254 cterm=bold",
        RgFlowInputPath     = "guifg=black   guibg=#e0e0e0 ctermfg=0 ctermbg=254",
    },
}

local function apply_color(colors)
    for group_name, definition in pairs(colors) do
        if vim.fn.hlexists(group_name) == 0 then
            vim.cmd("highlight " .. group_name .. " " .. definition)
        end
    end
end

local function apply_keymaps(mappings)
    for mode, mode_mappings in pairs(mappings) do
        for keymap, func_name in pairs(mode_mappings) do
            if string.sub(func_name, 1, 5) == "open_" then
                -- These are keymaps that are outside of the rgflow pop up window, or the quickfix window
                vim.keymap.set(mode, keymap, require("rgflow")[func_name], {noremap = true})
            end
        end
    end
end

local function apply_settings(settings)
    apply_color(settings.colors)
    apply_keymaps(settings.mappings)
    M.SETTINGS = settings
end

function M.setup(user_settings)
    local settings = vim.tbl_deep_extend("force", defaults, user_settings)
    apply_settings(settings)
end

-- Provide a getter function to access the settings
-- The table may change or be reassigned, and hence modules that import it will
-- loose their reference to the current settings
function M.get_settings()
    return M.SETTINGS
end

return M
