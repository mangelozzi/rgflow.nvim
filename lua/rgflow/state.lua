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
    started_adding = false,-- Currently added results for the current search
    search_exit = false,-- Whether the spawn rg search phase has exitted (currently not used)
    found_que = {},     -- Search results that have been found but not added to the quickfix list yet
    previous_print_time = 0,
    handle = nil,       -- UV spawn job handle
    highlight_namespace_id = vim.api.nvim_create_namespace("rgflow.nvim"),
    ui_autocmd_group = vim.api.nvim_create_augroup("RgFlowUiGroup", {clear = true}),
    applied_settings = {},
    custom_start = nil, -- Instead of calling built in function `start`, call a user provided custom function with the pattern/flags/path
    callback = nil,     -- Optional callback function to call after search has completed, a hook for customisation
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
    STATE.search_exit = false
end

return M
