-- When results are added to qf their paths are changed to be relative to PWD
-- hence the line changes in length

local M = {}
local api = vim.api
local utils = require("rgflow.utils")
local get_settings = require("rgflow.settingslib").get_settings
local zs_ze = require("rgflow.settingslib").zs_ze
local get_state = require("rgflow.state").get_state
local messages = require("rgflow.messages")
local modes = require("rgflow.modes")

-- Example in Linux: foo/bar/baz.js:19:11:    - `{% foo 'data-form="office prefix' %}`
local LINUX_QF_PATTERN = "^([^:]+):(%d+):(%d+):(.-)$"
-- Example in Windows: C:\Users\Michael\foo\bar\baz.js:1:261003:[Omitted long line with 43 matches]
local WIN_QF_PATTERN = "^(.:[^:]+):(%d+):(%d+):(.-)$"

local ZS_ZE_LEN = #zs_ze

function M.calc_qf_title(STATE, qf_count)
    return messages.calc_status_msg(STATE, qf_count)
end

local function get_qf_buffer_nr()
    return vim.fn.getqflist({qfbufnr = true}).qfbufnr
end

local function get_qf_buffer_cnt()
    return vim.api.nvim_buf_line_count(get_qf_buffer_nr())
end

local function get_qf_buffer_lines(start_idx, end_idx)
    -- dont iterate getqflist entries because they dont return the filename, which is before each entry
    local qf_buf_nr = get_qf_buffer_nr()
    local lines = vim.api.nvim_buf_get_lines(qf_buf_nr, start_idx - 1, end_idx, true)
    return lines
end

local function extractQfInfo(line)
    local pattern = LINUX_QF_PATTERN
    if line:sub(2, 2) == ":" then
        pattern = WIN_QF_PATTERN
    end
    local filename, lnum, col, text = line:match(pattern)
    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = col,
        text = text
    }
end

local function correct_info(info, match_cnt)
    -- Remove the effects of the added zs_ze delimiters
    -- the colnum reported by rg with include the ze_ze, subtract it
    if not info.col then
        -- Sometimes no match if the line truncated cause its too long
        return
    end
    local end_pos = info.text:find(zs_ze, info.col + 1, true)
    if not end_pos then
        -- Sometimes no match if the line truncated cause its too long
        return
    end
    local start_idx = info.col - (ZS_ZE_LEN * match_cnt * 2)
    local end_idx = end_pos - (ZS_ZE_LEN * (match_cnt + 1) * 2)
    info.col = start_idx
    -- We don't set info.end_col cause then the result in the QF windows is hard to read with the end column number (staggers results a lot)
    info.user_data = {end_col = end_idx}
    info.text2 = info.text
    info.text = info.text:gsub(zs_ze, "")
end

local function parseQfLines(buffer)
    local ret = {}
    local match_cnt = 0
    local previous_file = nil
    local previous_lnum = nil
    for _, line in ipairs(buffer) do
        local info = extractQfInfo(line)
        if previous_lnum == info.lnum and previous_file == info.filename then
            match_cnt = match_cnt + 1
        else
            match_cnt = 0
            previous_file = info.filename
            previous_lnum = info.lnum
        end
        correct_info(info, match_cnt)
        table.insert(ret, info)
    end
    return ret
end

local function clear_pattern_highlights(STATE)
    local qf_buf_nr = vim.fn.getqflist({qfbufnr = true}).qfbufnr
    vim.api.nvim_buf_clear_namespace(qf_buf_nr, STATE.highlight_namespace_id, 0, -1)
end

local function apply_line_hl(STATE, lnum, start_col, end_col)
    local qf_buf_nr = get_qf_buffer_nr()
    vim.api.nvim_buf_add_highlight(
        qf_buf_nr,
        STATE.highlight_namespace_id,
        "RgFlowQfPattern",
        lnum - 1,
        start_col,
        end_col
    )
end

-- Mark groups with RgFlowInputPattern for when search terms highlight goes away
local function set_and_apply_pattern_highlights(start_idx, end_idx)
    local STATE = get_state()
    local items = vim.fn.getqflist({items = true}).items

    local qf_buffer_cnt = get_qf_buffer_cnt()
    if end_idx > qf_buffer_cnt then
        print(
            "end_idx out of range in set_and_apply_pattern_highlights, end_idx: " ..
                end_idx .. ", and QF Buffer count: " .. qf_buffer_cnt
        )
        end_idx = qf_buffer_cnt
    end
    local buffer_lines = get_qf_buffer_lines(start_idx, end_idx)

    start_idx = start_idx or 1
    end_idx = end_idx or #items
    for item_nr = start_idx, end_idx do
        local item = items[item_nr]
        -- buffer_lines is only about the chunk size, where iten_nr is the full range of qf list
        local line = buffer_lines[item_nr - start_idx + 1]
        local text_start_idx = #line - #item.text
        if item.user_data and item.user_data.end_col then
            -- might not be a match due to truncation of line
            local end_col = item.user_data.end_col
            item.user_data = {
                hl_start = text_start_idx + item.col - 1,
                hl_end = text_start_idx + end_col
            }
            local success, error =
                pcall(apply_line_hl, STATE, item_nr, item.user_data.hl_start, item.user_data.hl_end)
            if (error) then
                print_error(error)
            end
        end
    end
    -- Save the user data to the QF List
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #items), items = items})
end

-- Mark groups with RgFlowInputPattern for when search terms highlight goes away
function M.apply_pattern_highlights()
    local STATE = get_state()
    clear_pattern_highlights(STATE)
    local items = vim.fn.getqflist({items = true}).items
    for i, item in ipairs(items) do
        if item.user_data then
            apply_line_hl(STATE, i, item.user_data.hl_start, item.user_data.hl_end)
        end
    end
end

-- The usual /term highlights
local function apply_search_term_highlight()
    -- Remember 0 is considered true in lua
    if get_settings().incsearch_after then
        -- Set incremental search to be the same value as pattern
        vim.fn.setreg("/", get_state().pattern, "c")
        -- Trigger the highlighting of search by turning hl on
        api.nvim_set_option("hlsearch", true)
    end
end

--- An operator to delete linewise from the quickfix window.
-- @mode - Refer to module doc string at top of this file.
function M.delete_operator(mode)
    local STATE = get_state()

    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local buffer, line, col = unpack(vim.fn.getpos("v"))
    local startl, endl, before = utils.get_line_range(mode)
    local count = endl - startl + 1
    local qf_list = vim.fn.getqflist()
    for _ = 1, count, 1 do
        table.remove(qf_list, startl)
    end
    STATE.found_cnt = STATE.found_cnt - count
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #qf_list), items = qf_list})
    M.apply_pattern_highlights()
    -- When deleting a visual set of lines, it's more intuitive to jump to the
    -- start of where the lines were deleted, rather then the current line place
    -- I.e. say you delete from line 4 to 6, now on line 6 you have to new lines
    -- above the cursor
    if before then
        vim.api.nvim_win_set_cursor(buffer, {math.min(#qf_list, line), col})
    else
        vim.fn.winrestview(win_pos)
    end
    -- Clear the current visual selection.
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, nil, true), "n")
end

--- An operator to mark lines in the quickfix window.
-- Marking is accomplished by prefixing the line with a given string.
-- @mode - Refer to module doc string at top of this file.
function M.mark_operator(add_not_remove, mode)
    local STATE = get_state()

    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl, _ = utils.get_line_range(mode)
    -- local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    local mark = get_settings().quickfix.mark_str
    local offset = #mark
    -- the quickfix list is an arrow of dictionary entries, an example of one entry:
    -- {'lnum': 57, 'bufnr': 5, 'col': 1, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': 'function! myal#StripTrailingWhitespace()'}
    -- HANDLE SIZE OFMARK STR
    if add_not_remove then
        for i = startl, endl, 1 do
            qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)", "%1" .. mark, 1)
            qf_list[i].user_data.hl_start = qf_list[i].user_data.hl_start + offset
            qf_list[i].user_data.hl_end = qf_list[i].user_data.hl_end + offset
        end
    else
        for i = startl, endl, 1 do
            local before_text = qf_list[i]["text"]
            if string.find(before_text, mark) then
                -- Don't allow to go before the start of the line
                qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)" .. mark, "%1", 1)
                qf_list[i].user_data.hl_start = qf_list[i].user_data.hl_start - offset
                qf_list[i].user_data.hl_end = qf_list[i].user_data.hl_end - offset
            end
        end
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #qf_list), items = qf_list})
    M.apply_pattern_highlights()
    vim.fn.winrestview(win_pos)
end

local function setup_qf_height()
    local win = vim.fn.getqflist({winid = 1}).winid
    local screen_height = vim.api.nvim_get_option("lines")
    local current_qf_height = api.nvim_win_get_height(win)
    if current_qf_height > screen_height / 2 then
        -- If the quickfix is currently taking up the whole screen, i.e. it is the
        -- only window, that setting its height forces the command bar to fill the
        -- whole screen
        return
    end
    local height = math.min(utils.get_qf_size() + 1, get_settings().quickfix.max_height_lines)
    api.nvim_win_set_height(win, height)
end

function M.populate()
    local STATE = get_state()
    if STATE.mode == modes.ABORTING then
        print("Aborted adding results.")
        STATE.mode = modes.ABORTED
        return
    end
    if STATE.mode == modes.ABORTED then
        return
    end

    local cnt = math.min(#STATE.found_que, get_settings().batch_size)
    local start_idx = utils.get_qf_size() + 1
    local end_idx = start_idx + cnt - 1

    -- Move the items from state.found to buffer
    local buffer = table.move(STATE.found_que, 1, cnt, 1, {})

    -- Remove the moved items from state.found
    -- table.move(STATE.found, cnt + 1, #STATE.found, 1, STATE.found)
    for _ = 1, cnt do
        table.remove(STATE.found_que, 1) -- Remove the first element
    end
    local final_run = STATE.mode == modes.ADDING and #STATE.found_que == 0
    if final_run then
        STATE.mode = modes.DONE
    end
    -- local chunk_lines = {unpack(STATE.added, start_idx, end_idx)}
    local qf_size = utils.get_qf_size()
    local new_qf_size = qf_size + #buffer

    local qf_info = {
        items = parseQfLines(buffer),
        title = M.calc_qf_title(STATE, new_qf_size)
    }
    vim.fn.setqflist({}, "a", qf_info)
    STATE.started_adding = true
    if final_run then
        messages.set_status_msg(STATE, {history = true, print = true})
    end

    set_and_apply_pattern_highlights(start_idx, end_idx)

    if #STATE.found_que > 0 then
        -- If the list of found matches
        vim.defer_fn(M.populate, 10)
    end
    setup_qf_height()
    if final_run and STATE.callback then
        -- If the user wishes to run a custom function after the search has completed
        STATE.callback()
    end
end

function M.setup_adding(STATE)
    clear_pattern_highlights(STATE)
    local create_qf_options = {title = M.calc_qf_title(STATE, 0), pattern = STATE.pattern}
    if get_settings().quickfix.new_list_always_appended then
        create_qf_options.nr = "$"
    end
    -- Create a new qf list, so use " ". Applies to colder/cnewer etc.
    -- Refer to `:help setqflist`
    vim.fn.setqflist({}, " ", create_qf_options) -- If what is used then list is ignored
    if get_settings().quickfix.open_qf_list then
        local open_qf_cmd_or_func = get_settings().quickfix.open_qf_cmd_or_func
        if type(open_qf_cmd_or_func) == "function" then
            open_qf_cmd_or_func()
        else
            api.nvim_command(open_qf_cmd_or_func)
        end
    end

    apply_search_term_highlight()

    -- Set char ASCII value 30 (<C-^>),"record separator" as invisible char around the pattern matches
    -- Conceal options set in ftplugin
    local qf_win_nr = vim.fn.getqflist({winid = true}).winid
    vim.fn.matchadd("Conceal", zs_ze, 12, -1, {conceal = "", window = qf_win_nr})
end

function M.get_current_qf_filenames() -- luacheck: ignore
    local qf_list = vim.fn.getqflist()
    local bufnrs = {}

    for _, item in ipairs(qf_list) do
        local bufnr = item.bufnr
        if bufnr and not bufnrs[bufnr] then
            bufnrs[bufnr] = true
        end
    end

    -- Convert buffer numbers to filenames
    local filenames = {}
    for bufnr, _ in pairs(bufnrs) do
        local bufname = vim.fn.bufname(bufnr)
        if bufname and #bufname > 0 then
            table.insert(filenames, bufname)
        end
    end
    return filenames
end

return M
