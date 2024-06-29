local M = {}
local api = vim.api
local utils = require("rgflow.utils")
local search = require("rgflow.search")
local get_settings = require("rgflow.settingslib").get_settings
local get_state = require("rgflow.state").get_state
local messages = require("rgflow.messages")
local modes = require("rgflow.modes")

local function setup_ui_autocommands(STATE)
    -- Clear old auto commands
    vim.api.nvim_clear_autocmds({group = STATE.ui_autocmd_group})
    vim.api.nvim_create_autocmd(
        "BufWipeout",
        {
            desc = "Autocommand to close the heading window when the input window is closed",
            group = STATE.RGFLOW_UI_GROUP,
            callback = function()
                if vim.api.nvim_win_is_valid(STATE.winh) then
                    vim.api.nvim_win_close(STATE.winh, true)
                end
                if vim.api.nvim_buf_is_valid(STATE.bufh) then
                    vim.api.nvim_buf_delete(STATE.bufh, {force = true})
                end
            end,
            buffer = STATE.bufi
        }
    )
    vim.api.nvim_create_autocmd(
        "WinEnter",
        {
            desc = "If the header window get focus, change to the input window",
            group = STATE.RGFLOW_UI_GROUP,
            callback = function()
                vim.fn.win_gotoid(STATE.wini)
            end,
            buffer = STATE.bufh
        }
    )
end

--- Creates the input dialogue and waits for input
-- If <CR> is pressed in normal mode, the search starts, <ESC> aborts.
-- @param pattern - The initial pattern to place in the pattern field
--                  when the dialogue opens.
function M.show_ui(pattern, flags, path)
    local STATE = get_state()

    pattern = pattern or ""
    flags = flags or get_settings().cmd_flags
    path = path or vim.fn.getcwd()

    -- get the editor's max width and height
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")
    local widthh = 10
    local widthi = width - widthh
    -- Height includes status line (1) and cmdline height
    local bottom = height - 1 - api.nvim_get_option("cmdheight")

    -- Create Buffers
    -- nvim_create_buf({listed}, {scratch})
    -- bufh / winh / widthh = heading window/buffer/width
    -- bufi / wini / widthi = input dialogue window/buffer/width
    STATE.bufi = api.nvim_create_buf(false, true)
    STATE.bufh = api.nvim_create_buf(false, true)

    -- Generate text content for the buffers
    -- REFER TO HERE FOR BORDER: https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
    local contenti = {flags, pattern, path}
    local contenth = {string.rep(get_settings().ui_top_line_char, width), " FLAGS    ", " PATTERN  ", " PATH     "}

    -- Add text content to the buffers
    -- nvim_buf_set_lines({buffer}, {start}, {end}, {strict_indexing}, {replacement})
    api.nvim_buf_set_lines(STATE.bufi, 0, -1, false, contenti)
    api.nvim_buf_set_lines(STATE.bufh, 0, -1, false, contenth)

    -- Window config
    local configi = {
        relative = "editor",
        anchor = "SW",
        width = widthi,
        height = 3,
        col = 10,
        row = bottom,
        style = "minimal"
    }
    local configh = {
        relative = "editor",
        anchor = "SW",
        width = width,
        height = 4,
        col = 0,
        row = bottom,
        style = "minimal"
    }

    -- Create windows
    -- nvim_open_win({buffer}, {enter}, {config})
    STATE.winh = api.nvim_open_win(STATE.bufh, false, configh)
    STATE.wini = api.nvim_open_win(STATE.bufi, true, configi) -- open input dialogue after so its ontop

    -- Setup Input window
    ---------------------
    api.nvim_win_set_option(STATE.wini, "winhl", "Normal:RgFlowInputBg")
    api.nvim_buf_set_option(STATE.bufi, "bufhidden", "wipe")
    api.nvim_buf_set_option(STATE.bufi, "filetype", "rgflow")
    -- Set the priority to 0 so a incsearch highlights the input window too
    vim.fn.matchaddpos("RgFlowInputFlags", {1}, 0, -1, {window = STATE.wini})
    vim.fn.matchaddpos("RgFlowInputPattern", {2}, 0, -1, {window = STATE.wini})
    vim.fn.matchaddpos("RgFlowInputPath", {3}, 0, -1, {window = STATE.wini})
    -- Position the cursor after the pattern
    api.nvim_win_set_cursor(STATE.wini, {2, string.len(pattern)})
    -- If the pattern is blank, enter insert mode
    if string.len(pattern) == 0 then
        api.nvim_command("startinsert")
    end

    -- Setup Heading window
    -----------------------
    api.nvim_buf_set_option(STATE.bufh, "bufhidden", "wipe")
    vim.fn.matchaddpos("RgFlowHeadLine", {1}, 11, -1, {window = STATE.winh})
    -- Instead of setting the window normal, the headings are highlighted with match add
    -- The advantage of this is when one incsearchs for a value which happen to be a
    -- heading, it will not be highlighted.
    vim.fn.matchaddpos("RgFlowHead", {2, 3, 4}, 11, -1, {window = STATE.winh})
    vim.fn.matchaddpos("RgFlowInputBg", {{2, widthh}, {3, widthh}, {4, widthh}}, 12, -1, {window = STATE.winh})
    -- If someone person ended up on the heading buffer, if <ESC> is pressed, abort the search
    -- Note the keymaps for the input dialogue are set in the filetype plugin
    api.nvim_buf_set_keymap(STATE.bufh, "n", "<ESC>", "<cmd>lua rgflow.abort_start()<CR>", {noremap = true})

    api.nvim_command("redraw!")
    STATE.mode = modes.OPEN
    setup_ui_autocommands(STATE)
end

local function set_patttern_if_blank(new_pattern)
    if not new_pattern or utils.trim_whitespace(new_pattern) == "" then
        return
    end
    local bufi = get_state().bufi
    local current_pattern = unpack(api.nvim_buf_get_lines(bufi, 1, 2, true))
    if utils.trim_whitespace(current_pattern) == "" then
        api.nvim_buf_set_lines(bufi, 1, 2, true, {new_pattern})
        return true
    end
    return false
end

function M.open(pattern, flags, path, options)
    options = options or {}
    local STATE = get_state()
    STATE.custom_start = options.custom_start
    STATE.callback = options.callback

    pattern = utils.trim_whitespace(pattern or '')
    if STATE.mode == modes.OPEN and vim.api.nvim_win_is_valid(STATE.wini) then
        local updated = set_patttern_if_blank(pattern)
        vim.fn.win_gotoid(STATE.wini)
        if updated == true then
            print("RgFlow pattern was blank and updated to: " .. pattern)
        else
            print("Switched to currently open RgFlow")
        end
        return
    elseif STATE.mode == modes.SEARCHING then
        print("Currently searching... First run the abort function: require('rgflow').abort")
    elseif STATE.mode == modes.ADDING then
        print("Currently adding results ... First run the abort function: require('rgflow').abort")
    else
        M.show_ui(pattern, flags, path)
    end
end

function M.start()
    local STATE = get_state()
    if vim.fn.pumvisible() ~= 0 then
        -- If the autocomplete pop up menu is shown, select current
        -- autocompletion match instead of starting
        return '<C-]>'
    end

    if vim.fn.mode() == "i" then
        -- If start search in insert mode with ENTER, will open QF in insert mode and gets lots of errors
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    end

    local bufi = get_state().bufi
    local flags, pattern, path = unpack(api.nvim_buf_get_lines(bufi, 0, 3, true))

    if pattern == "" and not STATE.custom_start then
        --- Prints a @msg to the command line with error highlighting.
        -- Does not raise an error (like echoerr does)
        vim.api.nvim_echo({{"PATTERN must not be blank.", "ErrorMsg"}}, false, {})
        return
    end
    if path == "" then
        vim.api.nvim_echo({{"PATH must not be blank. To use the current dir use ./", "ErrorMsg"}}, false, {})
        return
    end

    -- Closing the input window triggers an Autocmd to close the heading window
    -- see `api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! '..bufh..'"')` above
    api.nvim_win_close(get_state().wini, true)
    -- api.nvim_win_close(M.winh, true)

    local run_func = STATE.custom_start or search.run
    run_func(pattern, flags, path)
end

--- Closes the input dialogue
function M.close()
    local STATE = get_state()
    api.nvim_win_close(STATE.wini, true)
    STATE.mode = modes.IDLE
end

function M.parent_path()
    local STATE = get_state()
    local cur_path = unpack(api.nvim_buf_get_lines(STATE.bufi, 2, 3, true))
    local parent = vim.fn.fnamemodify(cur_path, ":h")
    api.nvim_buf_set_lines(STATE.bufi, 2, 3, true, { parent })
end

-- Define a function to create a floating terminal buffer and run a command
function M.show_rg_help()
    -- Get the current Neovim window dimensions
    local vim_width = vim.api.nvim_get_option("columns")
    local vim_height = vim.api.nvim_get_option("lines")

    -- Calculate the desired dimensions based on your criteria
    local desired_width = math.min(math.floor(vim_width * 0.9), 100)
    local desired_height = math.min(math.floor(vim_height * 0.8), 40)

    -- Create a new floating terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Create a floating window for the terminal buffer
    -- nvim_open_win({buffer}, {enter}, {config})
    local win =
        vim.api.nvim_open_win(
        buf,
        true,
        {
            width = desired_width,
            height = desired_height,
            relative = "editor",
            row = math.floor((vim_height - desired_height) / 2) - 4,
            col = math.floor((vim_width - desired_width) / 2),
            style = "minimal",
            border = "rounded",
            title = " Ripgrep Help "
        }
    )
    -- Run the command in the terminal buffer
    vim.fn.termopen("rg --help")

    -- Set the terminal buffer to insert mode (for user input)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "nofile")

    local lines = vim.fn.getbufline(buf, 1, "$")
    -- Remove the last line ... "[Process exited 0]"
    table.remove(lines, #lines - 1)
    vim.fn.setbufline(buf, 1, lines)

    -- Set the highlight group for the popup window
    vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
    vim.api.nvim_win_set_cursor(win, {1, 0})

    -- Pressing q or <ESC> closing the window (or they can just close the window)
    vim.keymap.set({"", "!"}, "q", "<C-W><C-C>", {buffer = buf, silent = true})
    vim.keymap.set({"", "!"}, "<ESC>", "<C-W><C-C>", {buffer = buf, silent = true})
end

return M
