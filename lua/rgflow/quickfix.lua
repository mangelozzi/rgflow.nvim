local M = {}
local api = vim.api
local utils = require('rgflow.utils')
local get_settings = require('rgflow.settingslib').get_settings
local get_state = require('rgflow.state').get_state

-- Since adding a lot of items to the quickfix window blocks the editor
-- Add a few then defer, continue
local currentIdx = 1
local chunkSize = 1000
local linesAdded = 0

--- An operator to delete linewise from the quickfix window.
-- @mode - Refer to module doc string at top of this file.
function M.qf_del_operator(mode)
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl = utils.get_line_range(mode)
    local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    for _=1,count,1 do
        table.remove(qf_list, startl)
    end
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist(qf_list, 'r')
    vim.fn.winrestview(win_pos)
end


--- An operator to mark lines in the quickfix window.
-- Marking is accomplished by prefixing the line with a given string.
-- @mode - Refer to module doc string at top of this file.
function M.qf_mark_operator(add_not_remove, mode)
    -- Only operates linewise, since 1 Quickfix entry is tied to 1 line.
    local win_pos = vim.fn.winsaveview()
    local startl, endl = utils.get_line_range(mode)
    -- local count = endl-startl + 1
    local qf_list = vim.fn.getqflist()
    local mark = get_settings()['quickfix']['mark_str']

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
    -- Don't create a new qf list, so use 'r'. Applies to colder/cnewer etc.
    vim.fn.setqflist(qf_list, 'r')
    vim.fn.winrestview(win_pos)
end






--- Highlight the search pattern matches in the quickfix window.
function M.hl_qf_matches()
    -- Needs to be called whenever quickfix window is opened
    -- :cclose will clear the following highlighting
    -- Called via the ftplugin mechanism.
    local win = vim.fn.getqflist({winid=1}).winid

    -- If the size of qf_list is zero, then return
    local qf_list = vim.fn.getqflist({id=0, items=0}).items
    if #qf_list == 0 then
        return
    end

    -- Get the first qf line and check it has rgflow highlighting markers, if
    -- not then return immediately.
    local first_qf_line = qf_list[1].text
    -- api.nvim_command("messages clear")

    local zs_ze = get_settings()['quickfix']['zs_ze_pattern_delimiter']
    if not string.find(first_qf_line, zs_ze) then
        -- First line does not have a zs_ze tag, so quicklist not from rgflow.
        return
    end

    -- Get a list of previous matches that were added to this window.
    local ok, rgflow_matches = pcall(function() return api.nvim_win_get_var(win, 'rgflow_matches') end)
    -- If therer is an error (no matches have been set yet), then use an empty list.
    if not ok then rgflow_matches = {} end

    -- For each existing match, delete the match
    for _, id in pairs(rgflow_matches) do
        vim.fn.matchdelete(id, win)
    end
    rgflow_matches = {}
    local id

    -- Set char ASCII value 30 (<C-^>),"record separator" as invisible char around the pattern matches
    -- Conceal options set in ftplugin
    id = vim.fn.matchadd("Conceal", zs_ze, 12, -1, {conceal="", window=win})
    table.insert(rgflow_matches, id)

    -- Highlight the matches between the invisible chars
    -- \{-n,} means match at least n chars, none greedy version
    -- priority 0, so that incsearch at priority 1 takes preference
    id = vim.fn.matchadd("RgFlowQfPattern", zs_ze..".\\{-1,}"..zs_ze, 0, -1, {window=win})
    table.insert(rgflow_matches, id)

    -- Store the matches as a window local list, so they can be deleted next time.
    api.nvim_win_set_var(win, 'rgflow_matches', rgflow_matches)
end


local function processChunk()
    local STATE = get_state()
    local endIndex = math.min(currentIdx + chunkSize - 1, #STATE.results)
    local chunkRows = {unpack(STATE.results, currentIdx, endIndex)}

    local title="  "..STATE.pattern.." (".. #STATE.results .. ")   "..STATE.path
    vim.fn.setqflist({}, 'a', {title = title, lines = chunkRows})

    if currentIdx <= #STATE.results then
        currentIdx = endIndex + 1
        linesAdded = linesAdded  + #chunkRows
        print('Adding ... ' .. linesAdded .. ' of ' .. #STATE.results)
        vim.defer_fn(processChunk, 0)
    else
        print("Added "..STATE.match_cnt.." ... done")
    end
end


M.populate_with_results = function()
        -- Create a new qf list, so use ' '. Applies to colder/cnewer etc.
        -- Refer to `:help setqflist`

        local STATE = get_state()
        if STATE.match_cnt > 1 then
            api.nvim_command('copen')
        end

        --- vim.fn.setqflist({}, ' ', {title=STATE.title, lines=STATE.results})
        linesAdded = 0
        processChunk()

        if get_settings()['quickfix']['open_qf_list'] then
            local height = STATE.match_cnt
            local max = get_settings()['quickfix']['max_height_lines']
            if height > max then height = max end
            if height < 3 then height = 3 end
            local win = vim.fn.getqflist({winid=1}).winid
            api.nvim_win_set_height(win, height)
        end

        -- Remember 0 is considered true in lua
        if get_settings()['incsearch_after'] then
            -- Set incremental search to be the same value as pattern
            vim.fn.setreg("/", STATE.pattern, "c")
            -- Trigger the highlighting of search by turning hl on
            api.nvim_set_option("hlsearch", true)
        end
        -- Note: rgflow.hl_qf_matches() is called via ftplugin when a QF window
        -- is opened.
end

return M
