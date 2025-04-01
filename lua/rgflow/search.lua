local M = {}
local uv = vim.loop
local quickfix = require("rgflow.quickfix")
local get_state = require("rgflow.state").get_state
local set_state_searching = require("rgflow.state").set_state_searching
local utils = require("rgflow.utils")
local settings = require("rgflow.settingslib")
local get_settings = settings.get_settings
local messages = require("rgflow.messages")
local modes = require("rgflow.modes")

local MIN_PRINT_TIME = 0.5 -- A float in seconds

local std_out_buffer = nil

--- The stderr handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stderr(err, data)
    -- On exit stderr will run with nil, nil passed in
    -- err always seems to be nil, and data has the error message
    if not err and not data then
        return
    end
    local STATE = get_state()

    STATE.error_cnt = STATE.error_cnt + 1
    vim.schedule(
        function()
            vim.api.nvim_err_writeln(data)
        end
    )
end

--- The stdout handler for the spawned job
-- @param err and data - Refer to module doc string at top of this file.
local function on_stdout(err, data)
    local STATE = get_state()
    local first = STATE.found_cnt == 0
    local found_was_empty = #STATE.found_que == 0

    if STATE.mode == modes.ABORTING then
        return
    end
    if err then
        STATE.error_cnt = STATE.error_cnt + 1
        vim.schedule(
            function()
                vim.api.nvim_err_writeln("ERROR: " .. vim.inspect(err) .. " >>> " .. vim.inspect(data), true)
            end
        )
    end
    if data then
        local vals = vim.split(data, "\n", true)
        if std_out_buffer and vals then
            vals[1] = std_out_buffer .. vals[1]
            std_out_buffer = nil
        end
        local complete_output = data:sub(-1) == "\n"
        if not complete_output then
            -- pop off the last incomplete string and store it
            local last_bit = table.remove(vals)
            if std_out_buffer then
                std_out_buffer = std_out_buffer .. last_bit
            else
                std_out_buffer = last_bit
            end
        end
        for _, d in pairs(vals) do
            local line = utils.trim_whitespace(d)
            if line ~= "" then
                table.insert(STATE.found_que, line)
                STATE.found_cnt = STATE.found_cnt + 1
            end
        end

        local current_time = os.clock()
        if current_time - STATE.previous_print_time > MIN_PRINT_TIME then
            -- If print too often, it's hard to exit vim cause flood of messages appearing, and it's already hard enough to exit vim.
            STATE.previous_print_time = current_time
            messages.set_status_msg(STATE, {print = not STATE.started_adding, qf = true})
        end

        if first then
            vim.schedule(
                function()
                    quickfix.setup_adding(STATE)
                end
            )
        end
        if found_was_empty then -- was empty but now we have results
            -- The populating stops itself once it finishes it's found stack
            vim.schedule(quickfix.populate)
        end
    end
end

--- The handler for when the spawned job exits
local function on_exit()
    local STATE = get_state()
    STATE.search_exit = true
    if STATE.mode == modes.SEARCHING then
        if #STATE.found_que > 0 then
            -- Still adding
            STATE.mode = modes.ADDING
        else
            -- Found stack empty, can stop immediately
            STATE.mode = modes.DONE
        end
    end
    messages.set_status_msg(STATE, {print = true, history = STATE.found_cnt == 0, qf = true})
end

--- Starts the async ripgrep job
local function spawn_job()
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local STATE = get_state()
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

local function get_demo_cmd(pattern, flags_list, path)
    -- The args are passe din as an array so the tokenisation is handled automatically,
    -- whereas in bash instead of ` -g !**/static/*/jsapp/` one would do
    -- ` -g '!**/static/*/jsapp/'` to prevent bash from expanding the globs.
    --
    local escaped_flags = {}
    for _, flag in ipairs(flags_list) do
        table.insert(escaped_flags, vim.fn.shellescape(flag))
    end
    return "rg " .. table.concat(escaped_flags, " ") .. " " .. pattern .. " " .. path
end

--- Prepares the global STATE to be used by the search.
-- @return the global STATE
local function setup_search(pattern, flags, path)
    -- Update the setting's flags so it retains its value for the session.
    get_settings().cmd_flags = flags

    -- Default flags always included
    -- local rg_args = {"--vimgrep", "--no-messages"}
    -- For highlighting { ZS_ZE.."$0"..ZS_ZE }
    -- local rg_args = {"--vimgrep"}
    local rg_args = {"--vimgrep", "--replace", settings.zs_ze .. "$0" .. settings.zs_ze}

    -- 1. Add the flags first to the Ripgrep command
    -- The args will never contain spaces, the search term might, but thats following below
    -- The args are passe din as an array so the tokenisation is handled automatically,
    -- whereas in bash instead of ` -g !**/static/*/jsapp/` one would do
    -- ` -g '!**/static/*/jsapp/'` to prevent bash from expanding the globs.
    local flags_list = vim.split(flags, " ")

    -- for flag in flags:gmatch("[-%w]+") do table.insert(rg_args, flag) end
    for _, flag in ipairs(flags_list) do
        table.insert(rg_args, flag)
    end

    -- 2. Add the pattern
    -- Check if pattern starts with '--' and prefix it with '\'
    local patterns = utils.split_search_terms(pattern)

    for _, pat in pairs(patterns) do
        if string.sub(pat, 1, 1) == '-' then
            -- https://github.com/BurntSushi/ripgrep/issues/624
            -- If search term starts with darh, then add a `--` token beforehand
            table.insert(rg_args, '--')
        end
        -- Tokenisation handled by spawn - will handle if it contains multiple single and double quotes
        if #patterns > 1 then
            table.insert(rg_args, '-e')
        end
        table.insert(rg_args, pat)
    end

    -- 3. Add the search path
    if path == "qf" then
        local qf_filesnames = quickfix.get_current_qf_filenames()
        if #qf_filesnames == 0 then
            return "No files in quickfix list"
        end
        for _, qf_filename in ipairs(qf_filesnames) do
            table.insert(rg_args, qf_filename)
        end
    else
        table.insert(rg_args, path)
    end


    local demo_cmd = get_demo_cmd(pattern, flags_list, path)
    set_state_searching(rg_args, demo_cmd, pattern, path)
end

--- From the UI, it starts the ripgrep search.
function M.run(pattern, flags, path)
    local STATE = get_state()
    -- Add a command to the history which can be invoked to repeat this search
    local rg_cmd = "lua require('rgflow').open([[" .. pattern .. "]], [[" .. flags .. "]], [[" .. path .. "]])"
    vim.fn.histadd("cmd", rg_cmd)

    local rg_installed = vim.fn.executable("rg") ~= 0
    if not rg_installed then
        STATE.mode = modes.idle
        vim.api.nvim_err_writeln("rg is not avilable on path, have you installed RipGrep?")
        return
    end

    -- Global STATE used by the async job
    local errorMessage = setup_search(pattern, flags, path)
    if errorMessage then
        vim.api.nvim_err_writeln(errorMessage)
        return
    end
    -- Don't schedule the print, else may come after we finish!
    messages.set_status_msg(STATE, {print = true})
    spawn_job()
end

return M
