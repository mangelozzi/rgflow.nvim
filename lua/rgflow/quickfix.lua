-- When results are added to qf their paths are changed to be relative to PWD
-- hence the line changes in length

local M = {}
local api = vim.api
local utils = require("rgflow.utils")
local get_settings = require("rgflow.settingslib").get_settings
local get_state = require("rgflow.state").get_state
local zs_ze = require("rgflow.settingslib").zs_ze

-- Since adding a lot of items to the quickfix window blocks the editor
-- Add a few then defer, continue. Chunk size of 10'000 makes lua run out memory.
local CHUNK_SIZE = 1000

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
local function calc_pattern_highlights()
    local STATE = get_state()
    -- local qf_buf_nr = vim.fn.getqflist({qfbufnr = true}).qfbufnr

    -- dont iterate getqflist entries because they dont return the filename, which is before each entry
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
        -- local start_col, end_col = 1, 0
        STATE.hl_positions[i] = calc_positions(line)
    end

    -- vim.api.nvim_buf_set_option(qf_buf_nr, 'modifiable', true)
    -- vim.cmd('%s///g')
    -- vim.api.nvim_buf_set_option(qf_buf_nr, 'modifiable', false)

    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    -- local clean_line = line:gsub(zs_ze, "")

    -- remove zs_ze marks
    local qf_list = vim.fn.getqflist()
    for i = 1, #qf_list do
        qf_list[i]["text"] = string.gsub(qf_list[i]["text"], zs_ze, "")
    end
    vim.fn.setqflist({}, "r", {items = qf_list})
end

-- Mark groups with RgFlowInputPattern for when search terms highlight goes away
local function apply_pattern_highlights()
    local STATE = get_state()
    clear_pattern_highlights(STATE)
    for line_nr, positions in pairs(STATE.hl_positions) do
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
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {items = qf_list})
    apply_pattern_highlights()
    -- When deleting a visual set of lines, it's more intuitive to jump to the
    -- start of where the lines were deleted, rather then the current line place
    -- I.e. say you delete from line 4 to 6, now on line 6 you have to new lines
    -- above the cursor
    if before then
        vim.api.nvim_win_set_cursor(buffer, {line, col})
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
            qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)" .. mark, "%1", 1)
            for _, position in ipairs(STATE.hl_positions[i]) do
                position["zs"] = position["zs"] - offset
                position["ze"] = position["ze"] - offset
            end
        end
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist({}, "r", {items = qf_list})
    apply_pattern_highlights()

    vim.fn.winrestview(win_pos)
end

local function processChunk()
    local STATE = get_state()
    if STATE.mode == "aborting" then
        print("Aborted adding results.")
        STATE.mode = ""
        return
    end
    local start_idx = STATE.lines_added + 1
    local end_idx = math.min(STATE.lines_added + CHUNK_SIZE, #STATE.results)
    -- local chunk_lines = {}
    local chunk_lines = {unpack(STATE.results, start_idx, end_idx)}

    vim.fn.setqflist({}, "a", {lines = chunk_lines})
    -- local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if STATE.lines_added < #STATE.results then
        STATE.lines_added = STATE.lines_added + #chunk_lines
        print(" Adding ... " .. STATE.lines_added .. " of " .. #STATE.results)
        vim.defer_fn(processChunk, 0)
    else
        print(utils.get_done_msg(STATE))
        apply_search_term_highlight()
        calc_pattern_highlights()
        apply_pattern_highlights()
        STATE.mode = ""
        STATE.results = {} -- free up memory
    end
end

M.populate_with_results = function()
    -- Create a new qf list, so use ' '. Applies to colder/cnewer etc.
    -- Refer to `:help setqflist`

    local STATE = get_state()
    STATE.mode = "adding"
    STATE.hl_positions = {}
    clear_pattern_highlights(STATE)

    if STATE.match_cnt > 0 then
        api.nvim_command("copen")
        local title = "  " .. STATE.pattern .. " (" .. #STATE.results .. ")   " .. STATE.path
        local create_qf_options = {title = title, pattern = title}
        if get_settings().quickfix.new_list_always_appended then
            create_qf_options.nr = "$"
        end
        vim.fn.setqflist({}, " ", create_qf_options) -- If what is used then list is ignored
        if get_settings().quickfix.open_qf_list then
            local height = STATE.match_cnt
            local max = get_settings().quickfix.max_height_lines
            if height > max then
                height = max
            end
            if height < 3 then
                height = 3
            end
            local win = vim.fn.getqflist({winid = 1}).winid
            api.nvim_win_set_height(win, height)
        end

        -- Set char ASCII value 30 (<C-^>),"record separator" as invisible char around the pattern matches
        -- Conceal options set in ftplugin
        local qf_win_nr = vim.fn.getqflist({winid = true}).winid
        vim.fn.matchadd("Conceal", zs_ze, 12, -1, {conceal = "", window = qf_win_nr})

        processChunk()
    end
end

return M
