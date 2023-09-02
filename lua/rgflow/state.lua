local get_settings = require('rgflow.settingslib').get_settings

local M = {}

local STATE = {
    mode = '',          -- '' (means idle/inactive) / 'open' / 'searching' / 'adding' / 'aborting'
    bufi = nil,         -- Buffer - Input dialog
    bufh = nil,         -- Buffer - Heading dialog
    wini = nil,         -- window# - Input dialog
    winh = nil,         -- window# - Heading dialog
    pattern = '',       -- current pattern
    cmd_flags = get_settings().cmd_flags,    --current command flags
    path = nil,         -- current search path
    demo_cmd = nil,     -- what the command looks like if where to enter it into bash
    error_cnt = 0,      -- Search results error count
    match_cnt = 0,      -- Search results match count
    results = {},       -- Search results
    lines_added = 0,    -- Number of search results added to quick fix so far
    previous_print_time = 0,
    handle = nil,       -- UV spawn job handle
    highlight_namespace_id = vim.api.nvim_create_namespace("rgflow.nvim"),
    ui_autocmd_group = vim.api.nvim_create_augroup("RgFlowUiGroup", {clear = true}),
    applied_settings = {},
}

M.get_state = function()
    return STATE
end

return M
