local M = {}
local api = vim.api

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
    for _, line in ipairs(rghelp) do
        if not heading_found then
            if string.find(line, "OPTIONS:") then heading_found = true end
        else
            local _, _, flag_opt, desc = string.find(line, "^%s*(.-)%s%s+(.-)%s*$")
            local _, endi, flag = string.find(flag_opt, "^(-%w),%s")
            if flag then
                -- e.g.     -A, --after-context <NUM>               Show NUM lines after each match.
                local option_ = string.sub(flag_opt, endi, -1)
                local _, _, option = string.find(option_, "^%s*(.-)%s*$")
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
function M.flags_complete(findstart, base)
    if findstart == 1 then
        local pos = api.nvim_win_get_cursor(0)
        local row = pos[1]
        local col = pos[2]
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

return M
