-- When results are added to qf their paths are changed to be relative to PWD
-- hence the line changes in length
-- Also changes the line/col number formatting so becomes a different length
local M = {}
local api = vim.api
local utils = require("rgflow.utils")
local get_settings = require("rgflow.settingslib").get_settings
local get_state = require("rgflow.state").get_state

-- Since adding a lot of items to the quickfix window blocks the editor
-- Add a few then defer, continue. Chunk size of 10'000 makes lua run out memory.
local CHUNK_SIZE = 1000

    -- local rg_args = {"--vimgrep", "--replace", settings.zs_ze .. "$0" .. settings.zs_ze}

local function calc_hl_offset(zs_ze, line)
    print('line:', line)
    vim.fn.setqflist({}, " ", {lines = {line}})
    local lines = vim.fn.getqflist()
    vim.print('QF info', lines)
end

local function remove_zs_ze_chars(zs_ze, line)
    local zs = line:find(zs_ze, 1)
    if not zs then
        -- Sometimes no match due to: "[Omitted long line with 5 matches]"
        return line, nil, nil
    end
    local ze = line:find(zs_ze, zs + 1) - 1 -- -1 for the removal of zs
    local clean_line = line:gsub(zs_ze, "")
    return clean_line, zs, ze
end

-- -- Mark groups with RgFlowInputPattern too for when search terms hi goes away
local function apply_pattern_highlights(hi_info)
    local STATE = get_state()
    hi_info = hi_info or STATE.hl_info
    local zs_ze = require('rgflow.settingslib').zs_ze
    vim.api.nvim_buf_clear_namespace(0, STATE.highlight_namespace_id, 0, -1)
    -- dont iterate getqflist entries because they dont return the filename, which is before each entry
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
        -- local start_col, end_col = 1, 0
        local new_line, zs, ze = remove_zs_ze_chars(zs_ze, line)
            vim.api.nvim_buf_add_highlight(
                0,
                STATE.highlight_namespace_id,
                "RgFlowQfPattern",
                i - 1,
                zs - 1,
                ze
            )

        -- while true do
        --     -- start_col, end_col = line:find(STATE.pattern, end_col + 1)
        --     if not start_col or not end_col then
        --         break
        --     end
        --     vim.api.nvim_buf_add_highlight(
        --         0,
        --         STATE.highlight_namespace_id,
        --         "RgFlowQfPattern",
        --         i - 1,
        --         start_col - 1,
        --         end_col
        --     )
        --     start_col = end_col + 1
        -- end
    end
    -- for line_nr, hi_info in pairs(hi_info) do
    --     -- vim.print(hi_info)
    --     if hi_info.ze then
    --         print(hi_info.zs, '->', hi_info.ze, 'line: ', STATE.results[line_nr])
    --         vim.api.nvim_buf_add_highlight(
    --             0,
    --             STATE.highlight_namespace_id,
    --             "RgFlowQfPattern",
    --             line_nr - 1,
    --             hi_info.zs,
    --             hi_info.ze
    --         )
    --     end
    -- end
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
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local buffer, line, col = unpack(vim.fn.getpos("v"))
    local startl, endl, before = utils.get_line_range(mode)
    local count = endl - startl + 1
    local qf_list = vim.fn.getqflist()
    for _ = 1, count, 1 do
        table.remove(qf_list, startl)
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist(qf_list, "r")
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
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl, _ = utils.get_line_range(mode)
    -- local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    local mark = get_settings().quickfix.mark_str
    -- the quickfix list is an arrow of dictionary entries, an example of one entry:
    -- {'lnum': 57, 'bufnr': 5, 'col': 1, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': 'function! myal#StripTrailingWhitespace()'}
    if add_not_remove then
        for i = startl, endl, 1 do
            qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)", "%1" .. mark, 1)
        end
    else
        for i = startl, endl, 1 do
            qf_list[i]["text"] = string.gsub(qf_list[i]["text"], "^(%s*)" .. mark, "%1", 1)
        end
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist(qf_list, "r")
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
    local zs_ze = require('rgflow.settingslib').zs_ze
    -- local chunk_lines = {}
    local chunk_lines = {unpack(STATE.results, start_idx, end_idx)}

    if start_idx == 1 then
        calc_hl_offset(zs_ze, chunk_lines[1])
        return
    end

    vim.fn.setqflist({}, "a", {lines = chunk_lines})
        -- local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if STATE.lines_added < #STATE.results then
        STATE.lines_added = STATE.lines_added + #chunk_lines
        print(" Adding ... " .. STATE.lines_added .. " of " .. #STATE.results)
        vim.defer_fn(processChunk, 0)
    else
        print(utils.get_done_msg(STATE))
        apply_search_term_highlight()
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
    if STATE.match_cnt > 0 then
        api.nvim_command("copen")
        local title = "  " .. STATE.pattern .. " (" .. #STATE.results .. ")   " .. STATE.path
        local create_qf_options = {title = title, pattern = STATE.pattern}
        if get_settings().quickfix.new_list_always_appended then
            create_qf_options.nr = "$"
        end
        vim.fn.setqflist({}, " ", create_qf_options) -- If what is used then list is ignored
        STATE.hl_info = {}
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
        processChunk()
    end
end

return M
