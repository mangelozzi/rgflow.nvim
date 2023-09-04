local M = {}
local uv = vim.loop
local api = vim.api
local quickfix = require("rgflow.quickfix")
local utils = require("rgflow.utils")
local get_state = require("rgflow.state").get_state
local get_settings = require("rgflow.settingslib").get_settings

local MIN_PRINT_TIME = 0.5 -- A float in seconds

--- Schedules a message in the event loop to print.
-- @param msg - The message to print
local function schedule_print(msg, echom)
    local timer = uv.new_timer()
    local cmd = echom and "echom " or "echo "
    timer:start(
        100,
        0,
        vim.schedule_wrap(
            function()
                -- In vim escape a single quote with two quotes.
                vim.cmd(cmd .. "'" .. msg:gsub("'", "''") .. "'")
            end
        )
    )
end

local function get_status_msg(STATE)
    return " Searching ... " .. STATE.match_cnt .. " result" .. (STATE.match_cnt ~= 1 and "s" or "")
end

--- The stderr handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stderr(err, data)
    -- On exit stderr will run with nil, nil passed in
    -- err always seems to be nil, and data has the error message
    if not err and not data then
        return
    end
    local STATE = get_state()
    if STATE.mode ~= "searching" then
        return
    end

    STATE.error_cnt = STATE.error_cnt + 1
    local timer = uv.new_timer()
    timer:start(
        100,
        0,
        vim.schedule_wrap(
            function()
                api.nvim_command('echoerr "' .. data .. '"')
            end
        )
    )
end

--- The stdout handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stdout(err, data)
    local STATE = get_state()
    if STATE.mode ~= "searching" then
        return
    end

    if err then
        STATE.error_cnt = STATE.error_cnt + 1
        schedule_print("ERROR: " .. vim.inspect(err) .. " >>> " .. vim.inspect(data), true)
    end
    if data then
        local vals = vim.split(data, "\n")
        for _, d in pairs(vals) do
            if d ~= "" then
                -- If the last char is a ASCII 13 / ^M / <CR> then trim it
                STATE.match_cnt = STATE.match_cnt + 1
                if string.sub(d, -1, -1) == "\13" then
                    d = string.sub(d, 1, -2)
                end
                table.insert(STATE.results, d)
            end
        end
        local current_time = os.clock()
        if current_time - STATE.previous_print_time > MIN_PRINT_TIME then
            -- If print too often, it's hard to exit vim cause flood of messages appearing, and it's already hard enough to exit vim.
            schedule_print(get_status_msg(STATE), false)
            STATE.previous_print_time = current_time
        end
    end
end

--- The handler for when the spawned job exits
local function on_exit()
    local STATE = get_state()
    if STATE.mode ~= "searching" then
        -- Search was aborted
        return
    end
    if STATE.match_cnt > 0 then
        local plural = "s"
        if STATE.match_cnt == 1 then
            plural = ""
        end
        print(" Adding " .. STATE.match_cnt .. " result" .. plural .. " to the quickfix list...")
        api.nvim_command("redraw!")
        vim.schedule(
            function()
                -- Schedule it incase a lot of matches
                quickfix.populate_with_results()
            end
        )
    else
        STATE.mode = ""
        schedule_print(utils.get_done_msg(STATE), true)
    end
end

--- Starts the async ripgrep job
local function spawn_job()
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local STATE = get_state()
    print("Rgflow start search for:  " .. STATE.pattern)
    -- Append the following makes it too long (results in one having to press enter)
    -- .."  with  "..STATE.demo_cmd)

    -- https://github.com/luvit/luv/blob/master/docs.md#uvspawnpath-options-on_exit
    -- vim.print(STATE.rg_args)
    STATE.handle =
        uv.spawn(
        "rg",
        {
            args = STATE.rg_args,
            stdio = {stdin, stdout, stderr}
        },
        vim.schedule_wrap(
            function()
                stdout:read_stop()
                stderr:read_stop()
                stdout:close()
                stderr:close()
                STATE.handle:close()
                on_exit()
            end
        )
    )
    uv.read_start(stdout, on_stdout)
    uv.read_start(stderr, on_stderr)
end

--- Prepares the global STATE to be used by the search.
-- @return the global STATE
local function set_state(pattern, flags, path)
    -- Update the setting's flags so it retains its value for the session.
    get_settings().cmd_flags = flags

    -- Default flags always included
    -- local rg_args = {"--vimgrep", "--no-messages"}
    local rg_args = {"--vimgrep"}

    -- 1. Add the flags first to the Ripgrep command
    local flags_list = vim.split(flags, " ")

    -- set conceallevel=2
    -- syntax match Todo /bar/ conceal
    -- :help conceal

    -- for flag in flags:gmatch("[-%w]+") do table.insert(rg_args, flag) end
    for _, flag in ipairs(flags_list) do
        table.insert(rg_args, flag)
    end

    -- 2. Add the pattern
    table.insert(rg_args, pattern)

    -- 3. Add the search path
    table.insert(rg_args, path)

    local STATE = get_state()
    STATE.mode = "searching"
    STATE.rg_args = rg_args
    STATE.demo_cmd = "rg " .. flags .. " " .. pattern .. " " .. path
    STATE.pattern = pattern
    STATE.path = path
    STATE.error_cnt = 0
    STATE.match_cnt = 0
    STATE.results = {}
    STATE.lines_added = 0
end

--- From the UI, it starts the ripgrep search.
function M.run(pattern, flags, path)
    -- Add a command to the history which can be invoked to repeat this search
    local rg_cmd = "lua require('rgflow').open([[" .. pattern .. "]], [[" .. flags .. "]], [[" .. path .. "]])"
    vim.fn.histadd("cmd", rg_cmd)

    local rg_installed = vim.fn.executable("rg") ~= 0
    if not rg_installed then
        local STATE = get_state()
        STATE.mode = ""
        msg = "rg is not avilable on path, have you installed RipGrep?"
        schedule_print(msg, true)
        return
    end

    -- Global STATE used by the async job
    set_state(pattern, flags, path)
    -- Don't schedule the print, else may come after we finish!
    print(get_status_msg(get_state()))
    spawn_job()
end

return M
