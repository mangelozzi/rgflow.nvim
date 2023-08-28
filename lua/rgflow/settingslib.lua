local M = {}

-- Default settings
local defaults = {
    option1 = true,
    option2 = "default_value",
    subsettings = {
        suboption1 = 10,
        suboption2 = "sub_default"
    },
    -- rgflow_flags
    -- For some reason --no-messages makes it stop working
    -- seprated by a space
    -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
    cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",
    -- rgflow_set_incsearch
    -- After a search, whether to set incsearch to be the pattern searched for
    incsearch_after = true,
    mappings = {
        ["F31"] = "Search", -- " Start blank search
        ["F32"] = "searchCword", -- " Rip grep in files, use <cword> under the cursor as starting point
        ["F33"] = "searchPaste", -- " Start and paste contents of search register
        ["F34"] = "searchVisual", -- " Rip grep in files, use visual selection as starting point
        ["F35"] = "searchPreviousAgain"
    },
    quickfix = {
        -- rgflow_mark_str
        -- String to prepend when marking an entry in the quick fix
        mark_str = "▌",
        -- Open the quickfix window automatically after a serach
        -- g:rgflow_open_qf_list
        open_qf_list = true,
        -- The QF window is set to the height of the number of matches, but bounded
        -- to be between a min of 3 and a max of this variable:
        -- g:rgflow_qf_max_height
        max_height_lines = 7,
        mappings = {
            ["<F21>"] = "DeleteOperator",
            ["<F22>"] = "DeleteLine",
            ["<F23>"] = "DeleteVisual",
            ["<F24>"] = "MarkLine",
            ["<F25>"] = "MarkVisual",
            ["<F26>"] = "UnmarkLine",
            ["<F27>"] = "UnmarkVisual"
        }
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
        RgFlowInputPath     = "guifg=black   guibg=#e0e0e0 ctermfg=0 ctermbg=254"
    }
}

local function apply_color_settings(colors)
    for group_name, definition in pairs(colors) do
        if vim.fn.hlexists(group_name) == 0 then
            vim.cmd("highlight " .. group_name .. " " .. definition)
        end
    end
end

local function apply_settings(settings)
    M.settings = settings  -- Save the settings for run time access
    apply_color_settings(settings.colors)
    vim.print('setup rgflow with', settings)
end

function M.setup(user_settings)
    local settings = vim.tbl_deep_extend("force", defaults, user_settings)
    apply_settings(settings)
end

return M
