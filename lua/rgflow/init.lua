local M = {}
local utils = require('rgflow.utils')
local ui = require('rgflow.ui')
local quickfix = require('rgflow.quickfix')
local search = require('rgflow.search')

-- Exposed API
M.setup = require('rgflow.settingslib').setup

-- open UI - search pattern = blank
M.open_blank = ui.open
-- open UI - search pattern = <cword>
M.open_cword = function() ui.open(vim.fn.expand('<cword>')) end
-- open UI - search pattern = Previous search pattern that was executed
M.open_again = function() ui.open(require('rgflow.state').get_state()['pattern']) end
-- open UI - search pattern = First line of unnamed register as the search pattern
M.open_paste = function() ui.open(vim.fn.getreg()) end
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

-- Search with no UI, just pass in the required arguements, will default to:
--  pattern = blank
--  flags = previously used
--  path = PWD
M.search = function(pattern, flags, path) search.run(pattern, flags, path) end

M.qf_delete = quickfix.delete
M.qf_delete_line = quickfix.delete_line
M.qf_delete_visual = quickfix.delete_line

M.qf_mark = quickfix.mark
M.qf_mark_visual = quickfix.mark_line
M.qf_unmark = quickfix.unmark_line
M.qf_unmark_visual = quickfix.unmark_visual


return M
--[[

-- local api = vim.api
-- local rg = require('rgflow.rg')
-- local quickfix = require('rgflow.quickfix')
local get_settings = require('rgflow.settingslib').get_settings

local M = {}


-- Exposed API
M.setup = require('rgflow.settingslib').setup
M.start_blank = ui.open
M.start_cword = function() ui.open(vim.fn.expand('<cword>')) end
M.start_visual = function() ui.open(utils.get_visual_selection(vim.fn.visualmode())) end
M.start_previous = function() ui.open(utils.get_visual_selection(vim.fn.visualmode())) end

", -- " Start
"startCword", -- " 
"startPaste", -- " 
"startVisual", -- "
"startPreviousAgain
"searchPreviousAgain




    " KEY MAPPINGS
    " Rip grep in files, use <cword> under the cursor as starting point
    nnoremap <leader>rg :<C-U>lua rgflow.start_via_hotkey('n')<CR>
    " Start and paste contents of search register
    nnoremap <leader>rr :<C-U>lua rgflow.start_via_hotkey('n')<CR>0D"/p
    " Rip grep in files, use visual selection as starting point
    xnoremap <leader>rg :<C-U>call v:lua.rgflow.start_via_hotkey(visualmode())<Cr>
    --]]
