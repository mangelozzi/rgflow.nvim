local M = {}
local api = vim.api
local rg = require('rgflow.rg')
local utils = require('rgflow.utils')
local search = require('rgflow.search')
local get_settings = require('rgflow.settingslib').get_settings
local get_state = require('rgflow.state').get_state


--- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete()
    local linenr = api.nvim_win_get_cursor(0)[1]
    if vim.fn.pumvisible() ~= 0 then
        api.nvim_input("<C-N>")
    elseif linenr == 1 then
        -- Flags line - Using completefunc
        -- nvim_buf_set_option({buffer}, {name}, {value})
        api.nvim_buf_set_option(0, "completefunc", rg.flags_complete)
        api.nvim_input("<C-X><C-U>")
    elseif linenr == 2 then
        -- Pattern line
        api.nvim_input("<C-N>")
    elseif linenr == 3 then
        -- Filename line
        api.nvim_input("<C-X><C-F>")
    end
end


--- Creates the input dialogue and waits for input
-- If <CR> is pressed in normal mode, the search starts, <ESC> aborts.
-- @param pattern - The initial pattern to place in the pattern field
--                  when the dialogue opens.
function M.open(pattern, flags, path)
    pattern = pattern or ""
    flags   = flags or get_settings().cmd_flags
    path    = path or vim.fn.getcwd()

    -- get the editor's max width and height
    local width  = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")
    local widthh = 10
    local widthi = width - widthh
    -- Height includes status line (1) and cmdline height
    local bottom = height - 1 - api.nvim_get_option('cmdheight')

    -- Create Buffers
    -- nvim_create_buf({listed}, {scratch})
    -- bufh / winh / widthh = heading window/buffer/width
    -- bufi / wini / widthi = input dialogue window/buffer/width
    local bufi  = api.nvim_create_buf(false, true)
    local bufh  = api.nvim_create_buf(false, true)

    -- Generate text content for the buffers
    -- REFER TO HERE FOR BORDER: https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
    local contenti = {flags, pattern, path}
    local contenth = {string.rep("▄", width), " FLAGS    ", " PATTERN  ", " PATH     "}

    -- Add text content to the buffers
    -- nvim_buf_set_lines({buffer}, {start}, {end}, {strict_indexing}, {replacement})
    api.nvim_buf_set_lines(bufi, 0, -1, false, contenti)
    api.nvim_buf_set_lines(bufh, 0, -1, false, contenth)

    -- Window config
    local configi = {relative='editor', anchor='SW', width=widthi, height=3, col=10, row=bottom,  style='minimal'}
    local configh = {relative='editor', anchor='SW', width=width,  height=4, col=0,  row=bottom,  style='minimal'}

    -- Create windows
    -- nvim_open_win({buffer}, {enter}, {config})
    local winh = api.nvim_open_win(bufh, false, configh)
    local wini = api.nvim_open_win(bufi, true,  configi) -- open input dialogue after so its ontop

    -- Setup Input window
    ---------------------
    api.nvim_win_set_option(wini, 'winhl', 'Normal:RgFlowInputBg')
    api.nvim_buf_set_option(bufi, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(bufi, 'filetype', 'rgflow')
    -- Set the priority to 0 so a incsearch highlights the input window too
    vim.fn.matchaddpos('RgFlowInputFlags',   {1}, 0, -1, {window=wini})
    vim.fn.matchaddpos('RgFlowInputPattern', {2}, 0, -1, {window=wini})
    vim.fn.matchaddpos('RgFlowInputPath',    {3}, 0, -1, {window=wini})
    -- Position the cursor after the pattern
    api.nvim_win_set_cursor(wini, {2, string.len(pattern)})
    -- If the pattern is blank, enter insert mode
    if string.len(pattern) == 0 then
        api.nvim_command("startinsert")
    end

    -- Setup Heading window
    -----------------------
    api.nvim_buf_set_option(bufh, 'bufhidden', 'wipe')
    -- Autocommand to close the heading window when the input window is closed
    api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! '..bufh..'"')
    vim.fn.matchaddpos('RgFlowHeadLine', {1}, 11, -1, {window=winh})
    -- Instead of setting the window normal, the headings are highlighted with match add
    -- The advantage of this is when one incsearchs for a value which happen to be a
    -- heading, it will not be highlighted.
    vim.fn.matchaddpos('RgFlowHead',     {2, 3, 4}, 11, -1, {window=winh})
    vim.fn.matchaddpos('RgFlowInputBg',  {{2, widthh}, {3, widthh}, {4, widthh}}, 12, -1, {window=winh})
    -- IF someone person ended up on the heading buffer, if <ESC> is pressed, abort the search
    -- Note the keymaps for the input dialogue are set in the filetype plugin
    api.nvim_buf_set_keymap(bufh, "n", "<ESC>", "<cmd>lua rgflow.abort_start()<CR>", {noremap=true})

    api.nvim_command('redraw!')
    local state = get_state()
    state.bufi = bufi
    state.wini = wini
    state.winh = winh
end

function M.start()
    local bufi = get_state().bufi
    local flags, pattern, path = unpack(api.nvim_buf_get_lines(bufi, 0, 3, true))

    if pattern == "" then
        utils.print_error("PATTERN must not be blank.")
        return
    end
    if path == "" then
        utils.print_error("PATH must not be blank. To use the current dir try ./")
        return
    end

    -- api.nvim_win_close(wini, true)
    -- Closing the input window triggers an Autocmd to close the heading window
    api.nvim_win_close(get_state().wini, true)
    -- api.nvim_win_close(M.winh, true)
    search.run(pattern, flags, path)
end


--- Closes the input dialogue
function M.close()
    api.nvim_win_close(get_state().wini, true)
end

return M
