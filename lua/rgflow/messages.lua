local modes = require("rgflow.modes")
local utils = require("rgflow.utils")

local M = {}


function M.calc_status_msg(STATE, qf_size)
    local msg = " "
    msg = msg .. STATE.mode
    -- can't use utils.get_qf_cnt(), because the use calc_status_msg within setqflist() calls
    if #STATE.found_que == 0 then
        msg = msg .. " " .. qf_size .. " results"
    else
        msg = msg .. " " .. qf_size .. " of " .. STATE.found_cnt
    end
    msg = msg .. " | " .. STATE.pattern
    if STATE.error_cnt > 0 then
        msg = msg .. " | " .. STATE.error_cnt .. " errors"
    end
    msg = msg .. " | " .. STATE.path
    return msg
end

function M.set_status_msg(STATE, options)
    -- Options can have the following booleans: history, print, qf
    vim.schedule(
        function()
            local qf_size = options.qf_size or utils.get_qf_size()
            local msg = M.calc_status_msg(STATE, qf_size)
            if options.print then
                vim.api.nvim_echo({{msg, nil}}, options.history, {})
            end
            if options.qf then
                vim.fn.setqflist({}, "r", {title = msg})
            end
            vim.cmd("redraw!")
        end
    )
end

return M
