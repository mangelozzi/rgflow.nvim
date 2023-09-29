local utils = require("rgflow.utils")
local ui = require("rgflow.ui")
local quickfix = require("rgflow.quickfix")
local search = require("rgflow.search")
local get_state = require("rgflow.state").get_state
local modes = require("rgflow.modes")

local M = {}

-- Exposed API
M.setup = require("rgflow.settingslib").setup

-- open UI - Pass in args: pattern, flags, path
-- Unsupplied args will default to:
--  pattern = blank
--  flags = previously used
--  path = PWD
-- e.g. require('rgflow').open('foo', '--smart-case --no-ignore', '/home/bob/stuff')
M.open = ui.open

-- open UI - search pattern = blank (hence will start in insert mode)
M.open_blank = ui.open

-- open UI - search pattern = <cword> (hence will start in normal mode)
M.open_cword = function()
    ui.open(vim.fn.expand("<cword>"))
end

-- open UI - search pattern = Previous search pattern that was executed
M.open_again = function()
    ui.open(require("rgflow.state").get_state().pattern)
end

-- open UI - search pattern = First line of unnamed register as the search pattern
M.open_paste = function()
    ui.open(vim.fn.getreg())
end

-- open UI - search pattern = current visual selection
M.open_visual = function()
    local content = utils.get_visual_selection(vim.fn.mode())
    local first_line = utils.get_first_line(content)
    ui.open(first_line)
end

-- With the UI pop up open, start searching with the currently filled out fields
M.start = ui.start

-- Close the current UI window
M.close = ui.close

-- Skips the UI and executes the search immediately
-- Call signature: run(pattern, flags, path)
-- e.g. require('rgflow').search('foo', '--smart-case --no-ignore', '/home/bob/stuff')
M.search = search.run

-- Aborts - Closes the UI if open, if searching will stop, if adding results will stop
M.abort = function()
    local STATE = get_state()
    if STATE.mode == modes.ABORTING then
        print("Still aborting ...")
    elseif STATE.mode == modes.IDLE then
        print("RgFlow not running.")
    elseif STATE.mode == modes.OPEN then
        M.close()
        STATE.mode = modes.IDLE
        print("Aborted UI.")
    elseif STATE.mode == modes.SEARCHING then
        local uv = vim.loop
        uv.process_kill(STATE.handle, "SIGTERM")
        STATE.mode = modes.ABORTED
        print("Aborted searching.")
    elseif STATE.mode == modes.ADDING then
        STATE.mode = modes.ABORTING
    -- Handed in quickfix.lua
    end
end

M.show_rg_help = ui.show_rg_help

-- No operation
M.nop = function()
end

-- Return a version of last run rip grep that can be pasted into a shell
-- e.g. `local cmd = require('rgflow').get_cmd()`
M.get_cmd = function()
    return get_state().demo_cmd
end

-- Print a version of last run rip grep that can be pasted into a shell
M.print_cmd = function()
    return print(M.get_cmd())
end

M.qf_delete = function()
    quickfix.delete_operator(vim.fn.mode())
end

M.qf_delete_line = function()
    quickfix.delete_operator("line")
end

M.qf_delete_visual = function()
    quickfix.delete_operator(vim.fn.mode())
end

M.qf_mark = function()
    quickfix.mark_operator(true, "line")
end

M.qf_mark_visual = function()
    quickfix.mark_operator(true, vim.fn.mode())
end

M.qf_unmark = function()
    quickfix.mark_operator(false, "line")
end

M.qf_unmark_visual = function()
    quickfix.mark_operator(false, vim.fn.mode())
end

-- Auto complete with rgflags or buffer words or filepaths depending on the input box they are on
M.auto_complete = require("rgflow.autocomplete").auto_complete

M.print_status = function()
    vim.print(require("rgflow.state").get_state())
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(":messages<CR>", true, nil, true), "n")
end

return M
