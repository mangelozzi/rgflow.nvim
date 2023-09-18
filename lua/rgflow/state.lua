--[[
Example data of hl_positions:
STATE.hl_positions = {

    -- Line 1 - has one match
    {
        { zs = 1, ze = 4 },
    },

    -- Line 2 - has two matches on it
    -- E.g Say one is searching for `foo` and the lines is `foo = foo + 1`
    {
        { zs = 20, ze = 23 },
        { zs = 33, ze = 35 },
    },
}
]]

local modes = require('rgflow.modes')
local get_settings = require('rgflow.settingslib').get_settings
local M = {}

local STATE = {
    mode = modes.IDLE,
    bufi = nil,         -- Buffer - Input dialog
    bufh = nil,         -- Buffer - Heading dialog
    wini = nil,         -- window# - Input dialog
    winh = nil,         -- window# - Heading dialog
    pattern = '',       -- current pattern
    cmd_flags = get_settings().cmd_flags,    --current command flags
    path = nil,         -- current search path
    demo_cmd = nil,     -- what the command looks like if where to enter it into bash
    error_cnt = 0,      -- Search results error count
    found_cnt = 0,      -- Current count of results for current search
    started_adding = false,      -- Currently added results for the current search
    found_que = {},     -- Search results that have been found but not added to the quickfix list yet
    hl_positions = {},  -- The line numbers mapping to tables of zs/ze positions, see comment at top of file
    previous_print_time = 0,
    handle = nil,       -- UV spawn job handle
    highlight_namespace_id = vim.api.nvim_create_namespace("rgflow.nvim"),
    ui_autocmd_group = vim.api.nvim_create_augroup("RgFlowUiGroup", {clear = true}),
    applied_settings = {},
}

M.get_state = function()
    return STATE
end

function M.set_state_searching(rg_args, demo_cmd, pattern, path)
    STATE.mode = modes.SEARCHING
    STATE.rg_args = rg_args
    STATE.demo_cmd = demo_cmd
    STATE.pattern = pattern
    STATE.path = path
    STATE.error_cnt = 0
    STATE.found_que = {}
    STATE.found_cnt = 0
    STATE.started_adding = false
end

function M.set_state_adding()
    STATE.hl_positions = {}
end

return M
