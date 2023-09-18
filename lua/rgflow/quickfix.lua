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
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == zs_ze then
            match_cnt = match_cnt + 1
            if start then
                table.insert(positions, {zs = start, ze = i - match_cnt})
                start = nil
            else
                start = i - match_cnt
            end
        end
    end
    -- local clean_line = line:gsub(zs_ze, "")
    return positions
end

local function clear_pattern_highlights(STATE)
    vim.api.nvim_buf_clear_namespace(0, STATE.highlight_namespace_id, 0, -1)
end

-- Calculate the positions of the mark groups with RgFlowInputPattern to highlight
local function calc_pattern_highlights(start_idx, end_idx)
    local STATE = get_state()
    start_idx = start_idx or 1
    end_idx = end_idx or #STATE.hl_positions
    local qf_buf_nr = vim.fn.getqflist({qfbufnr = true}).qfbufnr

    -- dont iterate getqflist entries because they dont return the filename, which is before each entry
    local lines = vim.api.nvim_buf_get_lines(qf_buf_nr, start_idx - 1, end_idx, true)
    for i, line in ipairs(lines) do
        -- local start_col, end_col = 1, 0
        STATE.hl_positions[start_idx + i - 1] = calc_positions(line)
    end

    -- vim.api.nvim_buf_set_option(qf_buf_nr, 'modifiable', true)
    -- vim.cmd('%s///g')
    -- vim.api.nvim_buf_set_option(qf_buf_nr, 'modifiable', false)

    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    -- local clean_line = line:gsub(zs_ze, "")

    -- remove zs_ze marks
    local qf_list = vim.fn.getqflist()
    for i = start_idx, end_idx do
        qf_list[i]["text"] = string.gsub(qf_list[i]["text"], zs_ze, "")
    end
    local win_pos = vim.fn.winsaveview()
    vim.fn.setqflist({}, "r", {title = M.calc_qf_title(STATE, #qf_list), items = qf_list})
    vim.fn.winrestview(win_pos)
end

-- Mark groups with RgFlowInputPattern for when search terms highlight goes away
local function apply_pattern_highlights(start_idx, end_idx)
    local STATE = get_state()
    if not start_idx and not end_idx then
        clear_pattern_highlights(STATE)
    end
    start_idx = start_idx or 1
    end_idx = end_idx or #STATE.hl_positions
    for line_nr = start_idx, end_idx do
        local positions = STATE.hl_positions[line_nr]
        for _, position in ipairs(positions) do
            vim.api.nvim_buf_add_highlight(
                0,
                STATE.highlight_namespace_id,
                "RgFlowQfPattern",
                line_nr - 1,
                position["zs"],
                position["ze"]
            )
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
    local height = math.min(utils.get_qf_size() + 1, get_settings().quickfix.max_height_lines)
    local win = vim.fn.getqflist({winid = 1}).winid
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

    local cnt = math.min(#STATE.found_que, CHUNK_SIZE)
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
    vim.fn.setqflist({}, "a", {lines = buffer, title = M.calc_qf_title(STATE, new_qf_size)})
    STATE.started_adding = true
    if final_run then
        messages.set_status_msg(STATE, {history = true, print = true})
    end

    calc_pattern_highlights(start_idx, end_idx)
    apply_pattern_highlights(start_idx, end_idx)

    if #STATE.found_que > 0 then
        -- If the list of found matches
        vim.defer_fn(M.populate, 10)
    end
    setup_qf_height()
end

function M.setup_adding(STATE)
    set_state_adding()
    -- clear_pattern_highlights(STATE)
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
