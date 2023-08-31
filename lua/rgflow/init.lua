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
M.open_again = function() ui.open(require('rgflow.state').get_state().pattern) end
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

-- No operation
M.nop = function() end

-- Auto complete with rgflags or buffer words or filepaths depending on the input box they are on
-- M.auto_complete = vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-X><C-O>", true, true, true), "n", true)
M.auto_complete = require('rgflow.autocomplete').auto_complete

-- Search with no UI, just pass in the required arguements, will default to:
--  pattern = blank
--  flags = previously used
--  path = PWD
M.search = function(pattern, flags, path) search.run(pattern, flags, path) end

M.qf_delete         = function() require('rgflow.quickfix').delete_operator(vim.fn.mode()) end
M.qf_delete_line    = function() require('rgflow.quickfix').delete_operator('line') end
M.qf_delete_visual  = function() require('rgflow.quickfix').delete_operator(vim.fn.mode()) end
M.qf_mark           = function() require('rgflow.quickfix').mark_operator(true, 'line') end
M.qf_mark_visual    = function() require('rgflow.quickfix').mark_operator(true, vim.fn.mode()) end
M.qf_unmark         = function() require('rgflow.quickfix').mark_operator(false, 'line') end
M.qf_unmark_visual  = function() require('rgflow.quickfix').mark_operator(false, vim.fn.mode()) end

return M
