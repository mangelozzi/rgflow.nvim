local M = {}
local api = vim.api
local RG_HELP_DATA = nil;



--- Returns the flag info from the ripgrep help for auto-completion.
-- :h complete-functions
-- 	word		the text that will be inserted, mandatory
-- 	menu		extra text for the popup menu, displayed after "word"
local function get_rg_help_data(base)
    if RG_HELP_DATA then 
        return RG_HELP_DATA
    end
    local rghelp = vim.fn.systemlist("rg -h") -- summarized help, not --help
    local data = {}
    local heading_found = false
    -- vim.print('help', rghelp)
    for _, line in ipairs(rghelp) do
        if line  then
            if not heading_found then
                if string.find(line, "OPTIONS:") then heading_found = true end
            else
                local _, _, flag_opt, desc = string.find(line, "^%s*(.-)%s%s+(.-)%s*$")
                if flag_opt then
                    local _, endi, flag = string.find(flag_opt, "^(-%w),%s")
                    if flag then
                        -- e.g.     -A, --after-context <NUM>               Show NUM lines after each match.
                        local option_ = string.sub(flag_opt, endi, -1)
                        local _, _, option = string.find(option_, "^%s*(.-)%s*$")
                        -- print('---------------')
                        -- vim.print('flag   ', flag, 'desc', desc)
                        table.insert(data, {word=flag, menu=desc})
                        -- vim.print('option ', option, 'desc', desc)
                        table.insert(data, {word=option, menu=desc})
                    else
                        -- vim.print('flag_opt', flag_opt, 'desc', desc)
                        table.insert(data, {word=flag_opt, menu=desc})
                    end
                end
            end
        end
    end
    RG_HELP_DATA = data
    -- vim.print(RG_HELP_DATA)
    return RG_HELP_DATA
end

--- Returns matches form the flag info from the ripgrep help for auto-completion.
-- @param base - The start of the autocompletion tag to return autocomplete
--               data for.
-- @return - A table of matches, where each entry is like {word=flag, info=menu},
--           where flag is like "-A" or "--binary" and menu is extra info added
--           next to the suggested word.
-- If add {info=desc} is added to the dict, then makes an ugly window appear
local function get_rg_help_matches(base)
    local HELP_DATA = get_rg_help_data()
    -- print("---------")
    -- print("base is", base, 'type', type(base))
    if not(base) then
        -- print("base was falsey")
        return HELP_DATA
    end

    local flag_data = {}
    for _, data in ipairs(HELP_DATA) do
        if string.find(data['word'], base, 0,false) then
            -- print("added match")
            table.insert(flag_data, {word=data['word'], menu=data['desc']})
        end
    end
    -- vim.print('flag_data', flag_data)
    return flag_data
end
-- vim.cmd("messages clear")
-- get_rg_help_matches(' --sm')
-- vim.cmd("mess")


--- Auto-complete function for ripgrap flags
-- :h complete-functions
-- @param findstart and @base, and @return refer to :help complete-functions
-- On the first invocation the arguments are:
--    a:findstart  1
--    a:base	empty
-- 
-- The function must return the column where the completion starts.  It must be a
-- number between zero and the cursor column "col('.')".  This involves looking
-- at the characters just before the cursor and including those characters that
-- could be part of the completed item.  The text between this column and the
-- cursor column will be replaced with the matches.  If the returned value is
-- larger than the cursor column, the cursor column is used.
-- 
-- Negative return values:
--    -2	To cancel silently and stay in completion mode.
--    -3	To cancel silently and leave completion mode.
--    Another negative value: completion starts at the cursor column
-- 
-- On the second invocation the arguments are:
--    a:findstart  0
--    a:base	the text with which matches should match; the text that was
-- 		located in the first call (can be empty)

local function rg_flags_complete(findstart, base)
    if findstart == 1 then
        -- print("auto atuo plete333")
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
        local flag_data = get_rg_help_matches(base)
        return flag_data
    end
end


-- FLIPPIN NEOVIM BUG:
-- Setting completefunc to `v:lua.require('foo').bar` always receives `findstart` and `base` as `nil`
-- Have to create a global lua object, and use it as `v:lua.GLOBAL_FUNC`
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.require('rgflow.autocomplete').rg_flags_complete")
-- vim.api.nvim_buf_set_option(0, "completefunc", "v:lua.RG_FLAGS_COMPLETE")

-- RG_FLAGS_COMPLETE = rg_flags_complete
-- vim.cmd("messages clear")
-- vim.print(rg_flags_complete(1, ' --sm'))
-- vim.cmd("mess")

--- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete(findstart, base)
    print('Auto_complete>>', 'findstart', findstart, 'base', base)
    local linenr = api.nvim_win_get_cursor(0)[1]
    if linenr == 1 then
        return rg_flags_complete(findstart, base)
    elseif linenr == 2 then
        return rg_flags_complete(findstart, base)
    elseif linenr == 3 then
        return require('cmp').complete_items(findstart, base)
    end
end


return M
