-- Currently QuickfixCmdPost does not support :Cfilter and :Cfilter!
-- local NamespaceGroup = vim.api.nvim_create_augroup("RgFlowNameSpace", {clear = true})
-- local quickfix = require("rgflow.quickfix")
--
-- vim.api.nvim_create_autocmd(
--     {"QuickfixCmdPost"}, -- does not handle Cfilter nor Cfilter!
--     {
--         desc = "Sync hilight after :Cfilter and :Cfilter! commands",
--         group = NamespaceGroup,
--         callback = function() quickfix.apply_pattern_highlights() end,
--     }
-- )
-- vim.api.nvim_create_autocmd(
--     {"command"}, -- No way to run code after a command
--     {
--         pattern = "Cfilter,Cfilter!",
--         desc = "Sync hilight after :Cfilter and :Cfilter! commands",
--         group = NamespaceGroup,
--         callback = function() quickfix.apply_pattern_highlights() end,
--     }
-- )
