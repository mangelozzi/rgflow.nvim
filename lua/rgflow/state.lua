local get_settings = require('rgflow.settingslib').get_settings

local M = {}

local STATE = {
    bufi = nil,         -- Buffer - Input dialog
    wini = nil,         -- window# - Input dialog
    winh = nil,         -- window# - Heading dialog
    pattern = nil,      -- current pattern
    cmd_flags = get_settings().cmd_flags,    --current command flags
    path = nil,         -- current search path
    demo_cmd = nil,     -- what the command looks like if where to enter it into bash
    error_cnt = 0,      -- Search results error count
    match_cnt = 0,      -- Search results match count
    results = {}        -- Search results
}

--- Prepares the global STATE to be used by the search.
-- @return the global STATE
function M.set_state(pattern, flags, path)
    -- Update the setting's flags so it retains its value for the session.
    get_settings()["cmd_flags"] = flags
    local zs_ze = get_settings()["quickfix"]["zs_ze_pattern_delimiter"]

    -- Default flags always included
    -- For highlighting { ZS_ZE.."$0"..ZS_ZE }
    local rg_args = {"--vimgrep", "--no-messages", "--replace", zs_ze .. "$0" .. zs_ze}

    -- 1. Add the flags first to the Ripgrep command
    local flags_list = vim.split(flags, " ")

    -- set conceallevel=2
    -- syntax match Todo /bar/ conceal
    -- :help conceal

    -- for flag in flags:gmatch("[-%w]+") do table.insert(rg_args, flag) end
    for i, flag in ipairs(flags_list) do
        table.insert(rg_args, flag)
    end

    -- 2. Add the pattern
    table.insert(rg_args, pattern)

    -- 3. Add the search path
    table.insert(rg_args, path)

    STATE.rg_args = rg_args
    STATE.demo_cmd = 'rg ' .. flags .. " " .. pattern .. " " .. path
    STATE.pattern = pattern
    STATE.path = path
    STATE.error_cnt = 0
    STATE.match_cnt = 0
    STATE.results = {}
end

M.get_state = function()
    return STATE
end

return M
