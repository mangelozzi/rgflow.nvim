-- Default settings
return {
    -- Set the default rip grep flags and options for when running a search via
    -- RgFlow. Once changed via the UI, the previous search flags are used for 
    -- each subsequent search (until Neovim restarts).
    cmd_flags = "--smart-case --fixed-strings --no-fixed-strings --no-ignore --ignore --max-columns 500",

    -- After a search, whether to set incsearch to be the pattern searched for
    incsearch_after = true,

    -- The vim `completeopt` for when using autocomplete with the RgFlow UI open
    completeopt = "menuone,noinsert,noselect",

    -- ENABLE / DISABLE DEFAULT MAPPINGS
    -- Mappings to trigger RgFlow functions
    default_trigger_mappings = false,
    -- These mappings are only active when the RgFlow UI (panel) is open
    default_ui_mappings = true,
    -- QuickFix window only mapping
    default_quickfix_mappings = false,

    -- Since adding a lot of items to the quickfix window blocks the editor for
    -- a long time, we rather add search matches in batches, and then defer.
    -- The larger the batch size, the faster search results will be added, but 
    -- the more laggy the editor will be while adding results (defers less often). 
    batch_size = 500,

    mappings = {
        -- Mappings that all always present
        trigger = {
            -- Normal mode maps
            n = {
                ["<leader>rG"] = "open_blank",      -- Open UI - search pattern = blank
                ["<leader>rp"] = "open_paste",      -- Open UI - search pattern = First line of unnamed register as the search pattern
                ["<leader>rg"] = "open_cword",      -- Open UI - search pattern = <cword>
                ["<leader>rw"] = "open_cword_path", -- Open UI - search pattern = <cword> and path = current file's directory
                ["<leader>rs"] = "search",          -- Run a search with the current parameters
                ["<leader>ra"] = "open_again",      -- Open UI - search pattern = Previous search pattern
                ["<leader>rx"] = "abort",           -- Close UI / abort searching / abortadding results
                ["<leader>rc"] = "print_cmd",       -- Print a version of last run rip grep that can be pasted into a shell
                ["<leader>r?"] = "print_status",    -- Print info about the current state of rgflow (mostly useful for deving on rgflow)
            },
            -- Visual/select mode maps
            x = {
                ["<leader>rg"] = "open_visual", -- Open UI - search pattern = current visual selection
            },
        },
        -- Mappings that are local only to the RgFlow UI
        ui = {
            -- Normal mode maps
            n = {
                ["<CR>"]  = "start",         -- With the ui open, start a search with the current parameters
                ["<ESC>"] = "close",         -- With the ui open, discard and close the UI window
                ["?"]     = "show_rg_help",  -- Show the rg help in a floating window, which can be closed with q or <ESC> or the usual <C-W><C-C>
                ["<BS>"]  = "parent_path",   -- Change the path to parent directory
                ["<C-^>"] = "edit_alt_file", -- Switch to the alternate file
                ["<C-6>"] = "edit_alt_file", -- Switch to the alternate file
                ["<C-^>"] = "nop",           -- No operation
                ["<C-6>"] = "nop",           -- No operation
            },
            -- Insert mode maps
            i = {
                ["<CR>"]  = "start",         -- With the ui open, start a search with the current parameters (from insert mode)
                ["<TAB>"] = "auto_complete", -- Start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-N>"] = "auto_complete", -- Start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-P>"] = "auto_complete", -- Start autocomplete if PUM not visible, if visible use own hotkeys to select an option
            },
        },
        -- Mapping that are local only to the QuickFix window
        quickfix = {
            -- Normal
            n = {
                ["d"] = "qf_delete",        -- QuickFix normal mode delete operator
                ["dd"] = "qf_delete_line",  -- QuickFix delete a line from quickfix
                ["<TAB>"] = "qf_mark",      -- QuickFix mark a line in the quickfix
                ["<S-TAB>"] = "qf_unmark",  -- QuickFix unmark a line in the quickfix window
                ["<BS>"]  = "nop", -- No operation
                ["<C-^>"] = "nop", -- No operation - Probably don't want to switch to a buffer in the little quickfix window
                ["<C-6>"] = "nop", -- No operation
            },
            -- Visual/select mode maps
            x = {
                ["d"] = "qf_delete_visual",       -- QuickFix visual mode delete operator
                ["<TAB>"] = "qf_mark_visual",     -- QuickFix visual mode mark operator
                ["<S-TAB>"] = "qf_unmark_visual", -- QuickFix visual mode unmark operator
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
        RgFlowHead          = nil, -- The header colors for FLAGS / PATTERN / PATH blocks
        RgFlowHeadLine      = nil, -- The line along the top of the header
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = nil, -- The Input lines
        RgFlowInputFlags    = nil, -- The flag input line
        RgFlowInputPattern  = nil, -- The pattern input line
        RgFlowInputPath     = nil, -- The path input line
        ---- Quickfix
        RgFlowQfPattern     = nil, -- The highlighting of the pattern in the quickfix results
    },

    -- ui_top_line_char = "▄",
    --  Example chars: ━━━ ═══ ███  ▀▀▀ ▃▃▃   
    ui_top_line_char = "▃",

}
