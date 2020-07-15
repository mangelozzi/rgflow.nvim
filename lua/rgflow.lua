-- nvim-rgflow.lua Plugin
--
-- PROGRAM EXECUTION
--------------------
-- rgflow.start_via_hotkey()
--   or
-- rgflow.start_via_history()
--   then -> start_ui() -> wait for <CR> or <ESC>
--
-- If <ESC> then -> rgflow.abort()
-- If <CR>  then -> rgflow.start() -> get_config()
--                                 -> spawn_job -> on_stdout()
--                                 -> on_stderr()
--                                 -> on_exit()
--
-- COMMON ARGUMENTS
-- ----------------
-- @param mode - The vim mode, eg. "n", "v", "V", "^V", recommend calling this
-- function with visualmode() as this argument.
-- @param err and data - refer to https://github.com/luvit/luv/blob/master/docs.md#uvspawnpath-options-on_exit

--[[
TODO
cdo / cfdo update
https://github.com/thinca/vim-qfreplace/blob/master/autoload/qfreplace.vim
-> not easy in rgflow type window, disable undo passed certain point

docs

Mark preview hints appear to left on window, at moment its next to the
suggested word, refer to:
:h previewheight
:h completeopt

--]]


local api = vim.api
local loop = vim.loop
local zs_ze = "\30"  -- The start and end of pattern match invisible marker
rgflow = {}


--- Prints a @msg to the command line with error highlighting.
-- Does not raise an error.
local function print_error(msg)
    api.nvim_command("echohl ErrorMsg")
    api.nvim_command('echom "'..msg..'"')
    api.nvim_command("echohl NONE")
end


--- Adds a method to the table class to check if an @element is within @table.
-- @return true if the element is within the table,  else return false
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end


--- Returns the start and end line range for a given mode.
-- If the mode is visual, then the line range which the visual mode spands is
-- returned, ignoring column positions.
-- If the mode is normal, then it adds the [count] prefix to the current line.
-- @mode - Refer to module doc string at top of this file.
-- @return - The start line, and the end line numbers.
local function get_line_range(mode)
    -- call with visualmode() as the argument
    -- vnoremap <leader>zz :<C-U>call rgflow#GetVisualSelection(visualmode())<Cr>
    -- nvim_buf_get_mark({buffer}, {name})
    local startl, endl
    if mode == 'v' or mode=='V' or mode=='\22' then
        startl = unpack(api.nvim_buf_get_mark(0, "<"))
        endl   = unpack(api.nvim_buf_get_mark(0, ">"))
    else
        startl = vim.fn.line('.')
        endl = vim.v.count1 + startl - 1
    end
    return startl, endl
end


--- Retrieves the visually seleceted text
-- Example mapping: vnoremap <leader>zz :<C-U>call rgflow#GetVisualSelection(visualmode())<Cr>
-- @mode - Refer to module doc string at top of this file.
-- @return - A string containing the visually selected text, where lines are
--           joined with \n.
local function get_visual_selection(mode)
    -- nvim_buf_get_mark({buffer}, {name})
    local line_start, column_start = unpack(api.nvim_buf_get_mark(0, "<"))
    local line_end,   column_end   = unpack(api.nvim_buf_get_mark(0, ">"))
    line_start   = line_start - 1
    column_start = column_start + 1
    column_end   = column_end + 2
    -- nvim_buf_get_lines({buffer}, {start}, {end}, {strict_indexing})
    local lines = api.nvim_buf_get_lines(0, line_start, line_end, true)
    local offset = 1
    if api.nvim_get_option('selection') ~= 'inclusive' then local offset = 2 end
    if mode == 'v' then
        -- Must trim the end before the start, the beginning will shift left.
        lines[#lines] = string.sub(lines[#lines], 1, column_end - offset)
        lines[1]      = string.sub(lines[1], column_start, -1)
    elseif  mode == 'V' then
        -- Line mode no need to trim start or end
    elseif  mode == "\22" then
        -- <C-V> = ASCII char 22
        -- Block mode, trim every line
        for i,line in ipairs(lines) do
            lines[i] = string.sub(line, column_start, column_end - offset)
        end
    else
        return ''
    end
    return table.concat(lines, "\n")
end


--- For a given mode, get default pattern to use in a search
-- @mode - Refer to module doc string at top of this file.
-- @return - The guessed default pattern to use.
local function get_pattern(mode)
    local visual_modes = {v=true, V=true, ['\22']=true}
    local default_pattern
    if visual_modes[mode] then
        default_pattern = get_visual_selection(mode)
    else
        default_pattern = vim.fn.expand('<cword>')
    end
    return default_pattern
end


--- An operator to delete linewise from the quickfix window.
-- @mode - Refer to module doc string at top of this file.
function rgflow.qf_del_operator(mode)
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl = get_line_range(mode)
    local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    for i=1,count,1 do
        table.remove(qf_list, startl)
    end
    vim.fn.setqflist(qf_list, 'r')
    vim.fn.winrestview(win_pos)
end


--- An operator to mark lines in the quickfix window.
-- Marking is accomplished by prefixing the line with a given string.
-- @mode - Refer to module doc string at top of this file.
function rgflow.qf_mark_operator(add_not_remove, mode)
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl = get_line_range(mode)
    local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    local mark = api.nvim_get_var('rgflow_mark_str')

    -- the quickfix list is an arrow of dictionary entries, an example of one entry:
    -- {'lnum': 57, 'bufnr': 5, 'col': 1, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': 'function! myal#StripTrailingWhitespace()'}
    if add_not_remove  then
        for i=startl,endl,1 do
            qf_list[i]['text'] = string.gsub(qf_list[i]['text'], "^(%s*)", "%1"..mark, 1)
        end
    else
        for i=startl,endl,1 do
            qf_list[i]['text'] = string.gsub(qf_list[i]['text'], "^(%s*)"..mark, "%1", 1)
        end
    end
    vim.fn.setqflist(qf_list, 'r')
    vim.fn.winrestview(win_pos)
end


--- Returns the flag info from the ripgrep help for auto-completion.
-- @param base - The start of the autocompletion tag to return autocomplete
--               data for.
-- @return - A table of matches, where each entry is like {word=flag, info=menu},
--           where flag is like "-A" or "--binary" and menu is extra info added
--           next to the suggested word.
-- If add {info=desc} is added to the dict, then makes an ugly window appear
local function get_flag_data(base)
    local rghelp = vim.fn.systemlist("rg -h")
    local flag_data = {}
    local heading_found = false
    for i, line in ipairs(rghelp) do
        if not heading_found then
            if string.find(line, "OPTIONS:") then heading_found = true end
        else
            local _, _, flag_opt, desc = string.find(line, "^%s*(.-)%s%s+(.-)%s*$")
            local starti, endi, flag = string.find(flag_opt, "^(-%w),%s")
            if flag then
                -- e.g.     -A, --after-context <NUM>               Show NUM lines after each match.
                local option = string.sub(flag_opt, endi, -1)
                local _, _, option = string.find(option, "^%s*(.-)%s*$")
                if not base or string.find(flag, base, 1, true) then
                    table.insert(flag_data, {word=flag, menu=desc})
                end
                if not base or string.find(option, base, 1, true) then
                    table.insert(flag_data, {word=option, menu=desc})
                end
            else
                -- e.g.         --binary                            Search binary files.
                if not base or string.find(flag_opt, base, 1, true) then
                    table.insert(flag_data, {word=flag_opt, menu=desc})
                end
            end
        end
    end
    return flag_data
end


--- Auto-complete function for ripgrap flags
-- @param findstart and @base, and @return refer to :help complete-functions
function rgflow.flags_complete(findstart, base)
    if findstart == 1 then
        local pos = api.nvim_win_get_cursor(0)
        row = pos[1]
        col = pos[2]
        local line = api.nvim_buf_get_lines(0,row-1,row, false)[1]
        local s = ''
        for i=col,1,-1 do
            local char = tostring(string.sub(line, i, i))
            s = s .. ">".. char
            if char == " " then return i end
        end
        return 0
    else
        local flag_data = get_flag_data(base)
        return flag_data
    end
end


--- Highlight the search pattern matches in the quickfix window.
function rgflow.hl_qf_matches()
    -- Needs to be called whenever quickfix window is opened
    -- :cclose will clear the following highlighting
    -- Called via the ftplugin mechanism.
    local win = vim.fn.getqflist({winid=1}).winid

    -- Get the first qf line and check it has rgflow highlighting markers, if
    -- not then return immediately.
    local first_qf_line = vim.fn.getqflist({id=0, items=0}).items[1].text
    api.nvim_command("messages clear")
    if not string.find(first_qf_line, zs_ze) then
        -- First line does not have a zs_ze tag, so quicklist not from rgflow.
        return
    end

    -- Clear matches only affects the current window
    vim.fn.clearmatches(win)

    -- Set char ASCII value 30 (<C-^>),"record separator" as invisible char around the pattern matches
    -- Conceal options set in ftplugin
    vim.fn.matchadd("Conceal", zs_ze, 12, -1, {conceal="", window=win})

    -- Highlight the matches between the invisible chars
    -- \{-n,} means match at least n chars, none greedy version
    -- priority 0, so that incsearch at priority 1 takes preference
    vim.fn.matchadd("RgFlowQfPattern", zs_ze..".\\{-1,}"..zs_ze, 0, -1, {window=win})
end


--- Within the input dialogue, call the appropriate auto-complete function.
function rgflow.complete()
    local linenr = api.nvim_win_get_cursor(0)[1]
    if vim.fn.pumvisible() ~= 0 then
        api.nvim_input("<C-N>")
    elseif linenr == 1 then
        -- Flags line - Using completefunc
        -- nvim_buf_set_option({buffer}, {name}, {value})
        api.nvim_buf_set_option(0, "completefunc", "v:lua.rgflow.flags_complete")
        api.nvim_input("<C-X><C-U>")
    elseif linenr == 2 then
        -- Pattern line
        api.nvim_input("<C-N>")
    elseif linenr == 3 then
        -- Filename line
        api.nvim_input("<C-X><C-F>")
    end
end


--- Schedules a message in the event loop to print.
-- @param msg - The message to print
local function schedule_print(msg)
    local msg = msg
    local timer = loop.new_timer()
    timer:start(100,0,vim.schedule_wrap(function() print(msg) end))
end


--- The stderr handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stderr(err, data)
    -- On exit stderr will run with nil, nil passed in
    -- err always seems to be nil, and data has the error message
    if not err and not data then return end
    config.error_cnt = config.error_cnt + 1
    local timer = loop.new_timer()
    timer:start(100,0,vim.schedule_wrap(function()
        api.nvim_command('echoerr "'..data..'"')
    end))
end


--- The stdout handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stdout(err, data)
    if err then
        config.error_cnt = config.error_cnt + 1
        schedule_print("ERROR: "..vim.inspect(err).." >>> "..vim.inspect(data))
    end
    if data then
        local vals = vim.split(data, "\n")
        for _, d in pairs(vals) do
            if d ~= "" then
                -- If the last char is a ASCII 13 / ^M / <CR> then trim it
                config.match_cnt = config.match_cnt + 1
                if string.sub(d, -1, -1) == "\13" then d = string.sub(d, 1, -2) end
                table.insert(config.results, d)
            end
        end
        local plural = "s"
        if config.match_cnt == 1 then plural = "" end
        schedule_print("Found "..config.match_cnt.." result"..plural.." ... ")
    end
end


--- The handler for when the spawned job exits
local function on_exit()
    if config.match_cnt > 0 then
        local plural = "s"
        if config.match_cnt == 1 then plural = "" end
        print("Adding "..config.match_cnt.." result"..plural.." to the quickfix list...")
        api.nvim_command('redraw!')

        vim.fn.setqflist({}, 'r', {title=config.title, lines=config.results})

        if api.nvim_get_var('rgflow_open_qf_list') ~= 0 then
            api.nvim_command('copen')
        end

        -- Remember 0 is considered true in lua
        if api.nvim_get_var('rgflow_set_incsearch') ~= 0 then
            -- Set incremental search to be the same value as pattern
            vim.fn.setreg("/", config.pattern, "c")
            -- Trigger the highlighting of search by turning hl on
            api.nvim_set_option("hlsearch", true)
        end

        -- Note: rgflow.hl_qf_matches() is called via ftplugin when a QF window
        -- is opened.
    end
    -- Print exit message
    local msg = config.pattern.." ░ "..config.match_cnt.." result"..(config.match_cnt==1 and '' or 's')
    if config.error_cnt > 0 then
        msg = msg.." ("..config.error_cnt.." errors)"
    else
        msg = msg.." ░ "..config.demo_cmd
    end
    schedule_print(msg)
end


--- Starts the async ripgrep job
local function spawn_job()
    term = "function"
    local stdin  = loop.new_pipe(false)
    local stdout = loop.new_pipe(false)
    local stderr = loop.new_pipe(false)

    print("Rgflow start search for:  "..config.pattern.."  with  "..config.demo_cmd)

    -- https://github.com/luvit/luv/blob/master/docs.md#uvspawnpath-options-on_exit
    handle = loop.spawn('rg', {
        args = config.rg_args,
        stdio = {stdin, stdout, stderr}
    },
    vim.schedule_wrap(function()
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        handle:close()
        on_exit()
    end)
    )
    loop.read_start(stdout, on_stdout)
    loop.read_start(stderr, on_stderr)
end


--- Prepares the global config to be used by the search.
-- @return the global config
local function get_config(flags, pattern, path)
    -- Update the g:rgflow_flags so it retains its value for the session.
    api.nvim_set_var('rgflow_flags', flags)

    -- Default flags always included
    local rg_args    = {"--vimgrep", "--no-messages", "--replace",  zs_ze.."$0"..zs_ze}

    -- 1. Add the flags first to the Ripgrep command
    local flags_list = vim.split(flags, " ")

    -- set conceallevel=2
    -- syntax match Todo /bar/ conceal
    -- :help conceal

    -- for flag in flags:gmatch("[-%w]+") do table.insert(rg_args, flag) end
    for i,flag in ipairs(flags_list) do
        table.insert(rg_args, flag)
    end

    -- 2. Add the pattern
    table.insert(rg_args, pattern)

    -- 3. Add the search path
    table.insert(rg_args, path)

    local config = {
        rg_args=rg_args,
        demo_cmd=flags.." "..pattern.." "..path,
        pattern=pattern,
        path=path,
        error_cnt=0,
        match_cnt=0,
        title="  "..pattern.."    "..path,
        results={},
    }
    return config
end


--- Closes the input dialogue when <ESC> is pressed
function rgflow.abort()
    api.nvim_win_close(rgflow.wini, true)
end


--- From the UI, it starts the ripgrep search.
function rgflow.search()
    local flags, pattern, path = unpack(api.nvim_buf_get_lines(bufi, 0, 3, true))

    if pattern == "" then
        print_error("PATTERN must not be blank.")
        return
    end
    if path == "" then
        print_error("PATH must not be blank. To use the current dir try ./")
        return
    end

    -- api.nvim_win_close(wini, true)
    -- Closing the input window triggers an Autocmd to close the heading window
    api.nvim_win_close(rgflow.wini, true)
    -- api.nvim_win_close(rgflow.winh, true)

    -- Add a command to the history which can be invoked to repeat this search
    local rg_cmd = ':lua rgflow.start_via_history([['..flags..']], [['..pattern..']], [['..path..']])'
    vim.fn.histadd('cmd', rg_cmd)

    -- Global config used by the async job
    config = get_config(flags, pattern, path)
    spawn_job()
end


--- Creates the input dialogue and waits for input
-- If <CR> is pressed in normal mode, the search starts, <ESC> aborts.
-- @param pattern - The initial pattern to place in the pattern field
--                  when the dialogue opens.
local function start_ui(flags, pattern, path)
    -- bufh / winh / widthh = heading window/buffer/width
    -- bufi / wini / widthi = input dialogue window/buffer/width

    -- get the editor's max width and height
    local width  = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")
    local widthh = 10
    local widthi = width - widthh
    -- Height includes status line (1) and cmdline height
    local bottom = height - 1 - api.nvim_get_option('cmdheight')

    -- Create Buffers
    -- nvim_create_buf({listed}, {scratch})
    bufi  = api.nvim_create_buf(false, true)
    bufh  = api.nvim_create_buf(false, true)

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
    return bufi, wini, winh
end


-- Begins Rgflow search via the command search history, ie. q:
-- @param flags/pattern/path are saved in the command history, and then passed
--        into this function.
function rgflow.start_via_history(flags, pattern, path)
    -- If called from the command history, for example by c_^F or q:
    rgflow.buf, rgflow.wini, rgflow.winh = start_ui(flags, pattern, path)
end


-- Begins Rgflow search via a hotkey
-- @mode - Refer to module doc string at top of this file.
function rgflow.start_via_hotkey(mode)
    -- If called from the hotkey
    -- api.nvim_command("messages clear")
    local flags   = api.nvim_get_var('rgflow_flags')
    local pattern = get_pattern(mode) or ""
    local path    = vim.fn.getcwd()
    rgflow.buf, rgflow.wini, rgflow.winh = start_ui(flags, pattern, path)
end

return rgflow
