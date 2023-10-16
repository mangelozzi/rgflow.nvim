-- When results are added to qf their paths are changed to be relative to PWD
-- hence the line changes in length

local M = {}
local api = vim.api
local utils = require("rgflow.utils")
local get_settings = require("rgflow.settingslib").get_settings
local zs_ze = require("rgflow.settingslib").zs_ze
local get_state = require("rgflow.state").get_state
local set_state_adding = require("rgflow.state").set_state_adding
local messages = require("rgflow.messages")
local modes = require("rgflow.modes")

-- Precompile these regex's to have the runtime compile cost of rebuilding them for each match
local QF_PATTERN = "^([^:]+):(%d+):(%d+):(.-)$"
local ZS_ZE_LEN = #zs_ze

-- Since adding a lot of items to the quickfix window blocks the editor
-- Add a few then defer, continue. Chunk size of 10'000 makes lua run out memory.
local CHUNK_SIZE = 1000

function M.calc_qf_title(STATE, qf_count)
    return messages.calc_status_msg(STATE, qf_count)
end

local function calc_positions(line)
    -- There maybe be more than one match per a line
    local positions = {}
    local start = nil
    local match_cnt = 0
    local zs_ze_len = #zs_ze
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == zs_ze then
            match_cnt = match_cnt + 1
            if start then
                -- Don't factor in the ze_zs into the column position of matches
                local offset = match_cnt * zs_ze_len
                print('zs_ze_len', zs_ze_len, 'offset', offset)
                table.insert(positions, {zs = start - offset, ze = i - match_cnt - offset})
                start = nil
            else
                start = i - match_cnt
            end
        end
    end
    -- local clean_line = line:gsub(zs_ze, "")
    print('---------------------got line')
    vim.print(line)
    print('positions')
    vim.print(positions)
    return positions
end

local function extractQfInfo(line)
    local filename, lnum, col, text = line:match(QF_PATTERN)
    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = col,
        text = text,
    }
end

local function split_str(input)
    local parts = {}
    local startIndex, endIndex = input:find(zs_ze, 1, true) -- true for plain matching
    while startIndex do
        table.insert(parts, input:sub(1, startIndex - 1))
        input = input:sub(endIndex + 1)
        startIndex, endIndex = input:find(zs_ze, 1, true)
    end
    if #input > 0 then
        table.insert(parts, input)
    end
    return parts
end

-- local function calculateColPositions(bits, match_cnt)
--     -- The return values are 1 index
--     local total = 0
--     local start_idx = 1 + (2 * match_cnt)
--     for i = 1, start_idx do
--         total = total + #bits[i]
--     end
--     -- start of match col nr, end of match col nr
--     return {total + 1, total + #bits[start_idx + 1]}
-- end


local function correct_info(info, match_cnt)
    -- Remove the effects of the added zs_ze delimiters
    -- the colnum reported by rg with include the ze_ze, subtract it
    local offset = ZS_ZE_LEN * match_cnt * 2
    local start_idx = info.col - (ZS_ZE_LEN * match_cnt * 2)
    local end_idx = info.text:find(zs_ze, info.col + 1, true) - (ZS_ZE_LEN * (match_cnt+1) * 2)
    info.col = start_idx
    info.end_col = end_idx
    info.text2 = info.text
    info.text = info.text:gsub(zs_ze, "")
end

local function parseQfLines(buffer)
    local ret = {}
    local match_cnt = 0
    local previous_line = nil
    for i, line in ipairs(buffer) do
        local info = extractQfInfo(line)
        if info.text == previous_line then
            match_cnt = match_cnt + 1
        else
            match_cnt = 0
            previous_line = info.text
        end
        correct_info(info,  match_cnt)
        table.insert(ret, info)
    end
    return ret
end

local function clear_pattern_highlights(STATE)
    local qf_buf_nr = vim.fn.getqflist({qfbufnr = true}).qfbufnr
    vim.api.nvim_buf_clear_namespace(qf_buf_nr, STATE.highlight_namespace_id, 0, -1)
end

-- Mark groups with RgFlowInputPattern for when search terms highlight goes away
local function apply_pattern_highlights(start_idx, end_idx)
    local STATE = get_state()
    local items = vim.fn.getqflist({items = true}).items
    start_idx = start_idx or 1
    end_idx = end_idx or #items
    print('start', start_idx, 'end', end_idx)
    for item_nr = start_idx, end_idx do
        local item = items[item_nr]
        vim.print(item)
        -- vim.api.nvim_buf_add_highlight(
        --     0,
        --     STATE.highlight_namespace_id,
        --     "RgFlowQfPattern",
        --     item_nr - 1,
        --     #item.filename + item.col,
        --     #item.filename + item.end_col
        -- )
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
        table.remove(STATE.hl_positions, startl)
    end
    STATE.found_cnt = STATE.found_cnt - count
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #qf_list), items = qf_list})
    apply_pattern_highlights()
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
            for _, position in ipairs(STATE.hl_positions[i]) do
                position["zs"] = position["zs"] + offset
                position["ze"] = position["ze"] + offset
            end
        end
    else
        for i = startl, endl, 1 do
            local before_change = qf_list[i]["text"]
            qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)" .. mark, "%1", 1)
            if before_change ~= qf_list[i]["text"] then
                -- If you try unmark beyond zero, dont keep shifting the highlighting
                for _, position in ipairs(STATE.hl_positions[i]) do
                    position["zs"] = position["zs"] - offset
                    position["ze"] = position["ze"] - offset
                end
            end
        end
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #qf_list), items = qf_list})
    apply_pattern_highlights()
    vim.fn.winrestview(win_pos)
end

local function setup_qf_height()
    local win = vim.fn.getqflist({winid = 1}).winid
    local screen_height = vim.api.nvim_get_option('lines')
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

    local qf_len_before = utils.get_qf_size()
    local cnt = math.min(#STATE.found_que, CHUNK_SIZE)

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
        title = M.calc_qf_title(STATE, new_qf_size),
    }
    vim.fn.setqflist({}, "a", qf_info)
    STATE.started_adding = true
    if final_run then
        messages.set_status_msg(STATE, {history = true, print = true})
    end

    apply_pattern_highlights(qf_len_before + 1, qf_len_before + #qf_info.items)

    if #STATE.found_que > 0 then
        -- If the list of found matches
        vim.defer_fn(M.populate, 10)
    end
    setup_qf_height()
end

function M.setup_adding(STATE)
    set_state_adding()
    clear_pattern_highlights(STATE)
    local create_qf_options = {title = M.calc_qf_title(STATE, 0), pattern = STATE.pattern}
    if get_settings().quickfix.new_list_always_appended then
        create_qf_options.nr = "$"
    end
    -- Create a new qf list, so use " ". Applies to colder/cnewer etc.
    -- Refer to `:help setqflist`
    vim.fn.setqflist({}, " ", create_qf_options) -- If what is used then list is ignored
    if get_settings().quickfix.open_qf_list then
        api.nvim_command("copen")
    end

    apply_search_term_highlight()

    -- Set char ASCII value 30 (<C-^>),"record separator" as invisible char around the pattern matches
    -- Conceal options set in ftplugin
    local qf_win_nr = vim.fn.getqflist({winid = true}).winid
    vim.fn.matchadd("Conceal", zs_ze, 12, -1, {conceal = "", window = qf_win_nr})
end

return M
