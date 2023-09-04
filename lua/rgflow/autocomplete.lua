local M = {}
local api = vim.api
local RG_HELP_DATA = nil

local function remove_header(lines)
    local index
    for i, line in ipairs(lines) do
        if string.match(line, "^OPTIONS%:") ~= nil then
            index = i
            break -- Exit the loop once the header is found and removed
        end
    end
    for _ = 1, index do
        table.remove(lines, 1)
    end
end

local function get_is_follow_on_line(line)
    return string.match(line, "^%s*%-") == nil
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function remove_blank_lines(lines)
    local new_lines = {}
    for _, line in ipairs(lines) do
        if line and trim(line) ~= "" then
            table.insert(new_lines, line)
        end
    end
    return new_lines
end

--- Returns the flag info from the ripgrep help for auto-completion.
-- :h complete-functions
-- 	word		the text that will be inserted, mandatory
-- 	menu		extra text for the popup menu, displayed after "word"
local function get_rg_help_data()
    if RG_HELP_DATA then
        return RG_HELP_DATA
    end
    local rghelp_raw = vim.fn.systemlist("rg -h") -- summarized help, not --help
    remove_header(rghelp_raw)
    local rghelp = remove_blank_lines(rghelp_raw)
    local data = {}
    local i = 1
    while i <= #rghelp - 1 do
        local line = rghelp[i]
        local next_line = rghelp[i + 1]
        if get_is_follow_on_line(next_line) then
            line = string.gsub(line, "\n", "") .. "    " .. next_line
            i = i + 2
        else
            i = i + 1
        end

        -- Lua regex implementation does not handle optional match groups
        --     -A, --after-context <NUM>                    Show NUM lines after each match.
        --         --auto-hybrid-regex                      Dynamically use PCRE2 if necessary.
        local match, rest
        -- Match the `-A` in a line like:
        --     -A, --after-context <NUM>                    Show NUM lines after each match.
        local abbr_flag_pattern = "%s*(-%w), (.*)"
        local abbr_flag, rest1 = string.match(line, abbr_flag_pattern)
        if (abbr_flag) then
            line = rest1
        end

        -- Match the `--auto-hybrid-regex` in a line like:
        --         --auto-hybrid-regex                      Dynamically use PCRE2 if necessary.
        local long_flag_pattern = "(%-%-[%w%-]+)%s(.*)"
        local long_flag, rest2 = string.match(line, long_flag_pattern)
        if (long_flag) then
            line = rest2
        end

        -- Match the `<PATTERNFILE>...` in a line like:
        --      -f, --file <PATTERNFILE>...                  Search for patterns from the given file.
        local arg_pattern = "(<[^% ]+)%s(.*)"
        local arg, rest3 = string.match(line, arg_pattern)
        if (arg) then
            line = rest3
        end

        -- Remaining part is the description
        local desc = trim(line)

        if abbr_flag then
            table.insert(data, {word = abbr_flag, menu = desc})
        end
        table.insert(data, {word = long_flag, menu = desc})
    end
    RG_HELP_DATA = data
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
    if not base then
        -- print("base was falsey")
        return HELP_DATA
    end

    local flag_data = {}
    for _, data in ipairs(HELP_DATA) do
        if string.find(data["word"], base, 0, false) then
            -- print("added match")
            table.insert(flag_data, {word = data["word"], menu = data["desc"]})
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

function M.rg_flags_complete(findstart, base)
    if findstart == 1 then
        -- print("auto atuo plete333")
        local pos = api.nvim_win_get_cursor(0)
        local row = pos[1]
        local col = pos[2]
        local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        local s = ""
        for i = col, 1, -1 do
            local char = tostring(string.sub(line, i, i))
            s = s .. ">" .. char
            if char == " " then
                return i
            end
        end
        return 0
    else
        local flag_data = get_rg_help_matches(base)
        return flag_data
    end
end

-- Within the input dialogue, call the appropriate auto-complete function.
function M.auto_complete()
    if vim.fn.pumvisible() ~= 0 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-N>", true, nil, true), "n")
        return
    end
    local linenr = api.nvim_win_get_cursor(0)[1]
    if linenr == 1 then
        -- Flags line - Using completefunc
        -- Set in ftafter/rgflow.lua
        -- vim.opt_local.omnifunc = "v:lua.RGFLOW_FLAGS_COMPLETE"
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-X><C-O>", true, nil, true), "n")
    elseif linenr == 2 then
        -- Pattern line
        -- Default autocomplete is an empty string
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-N>", true, nil, true), "n")
    elseif linenr == 3 then
        -- Filename line
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-X><C-F>", true, nil, true), "n")
    end
end

return M
