local M = {}
local api = vim.api

--- Returns the start and end line range for a given mode.
-- If the mode is visual, then the line range which the visual mode spands is
-- returned, ignoring column positions.
-- If the mode is normal, then it adds the [count] prefix to the current line.
-- @mode - Refer to module doc string at top of this file.
-- @return - The start line, and the end line numbers, and whether start was before end
function M.get_line_range(mode)
    -- call with visualmode() as the argument
    -- vnoremap <leader>zz :<C-U>call rgflow#GetVisualSelection(visualmode())<Cr>
    -- nvim_buf_get_mark({buffer}, {name})
    local startl, endl
    if mode == 'v' or mode=='V' or mode=='\22' then
        _, startl, _ = unpack(vim.fn.getpos('v'))
        _, endl,   _ = unpack(vim.fn.getpos('.'))
    else
        startl = vim.fn.line('.')
        endl = vim.v.count1 + startl - 1
    end
    if startl <= endl then
        return startl, endl, true
    else
        return endl, startl, false
    end
end


--- Retrieves the visually seleceted text
-- Example mapping: vnoremap <leader>zz :<C-U>call rgflow#GetVisualSelection(visualmode())<Cr>
-- @mode - The result of `vim.fn.mode()`
-- @return - A string containing the visually selected text, where lines are
--           joined with \n.
function M.get_visual_selection(mode)
    local _, l1, c1 = unpack(vim.fn.getpos('v'))
    local _, l2, c2   = unpack(vim.fn.getpos('.'))
    local line_start, line_end, column_start, column_end = l1, l2, c1, c2
    if l1 > l2 or l1==l2 and c2 > c1 then
        line_start, line_end, column_start, column_end = l2, l1, c2, c1
    end
    line_start   = line_start - 1
    column_end   = column_end + 2
    -- nvim_buf_get_lines({buffer}, {start}, {end}, {strict_indexing})
    local lines = api.nvim_buf_get_lines(0, line_start, line_end, true)
    local offset = 1
    if api.nvim_get_option('selection') ~= 'inclusive' then offset = 2 end
    if mode == 'v' then
        -- Must trim the end before the start, the beginning will shift left.
        lines[#lines] = string.sub(lines[#lines], 1, column_end - offset)
        lines[1]      = string.sub(lines[1], column_start, -1)
    elseif  mode == 'V' then
        -- Line mode no need to trim start or end
    elseif  mode == "\22" then
        -- <C-V> = ASCII char 22
        -- Block mode, trim every line
        for i,line in ipairs(lines) do
            lines[i] = string.sub(line, column_start, column_end - offset)
        end
    else
        return ''
    end
    -- vim.print('lines is', table.concat(lines, "\n"))
    return table.concat(lines, "\n")
end

function M.get_first_line(s)
    local lines = {}
    for line in s:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines[1]
end

--- For a given mode, get default pattern to use in a search
-- @mode - Refer to module doc string at top of this file.
-- @return - The guessed default pattern to use.
function M.get_pattern(mode)
    local visual_modes = {v=true, V=true, ['\22']=true}
    local default_pattern
    if visual_modes[mode] then
        default_pattern = M.get_visual_selection(mode)
    else
        default_pattern = vim.fn.expand('<cword>')
    end
    return default_pattern
end

--- Prints a @msg to the command line with error highlighting.
-- Does not raise an error.
function M.print_error(msg)
    api.nvim_command("echohl ErrorMsg")
    api.nvim_command('echom "'..msg..'"')
    api.nvim_command("echohl NONE")
end


function M.get_done_msg(STATE)
    -- local plural = STATE.match_cnt == 1 and "" or "s"
    local msg = " Added " .. STATE.match_cnt .. " │ " .. STATE.pattern
    if STATE.error_cnt > 0 then
        msg = msg .. " | " .. STATE.error_cnt .. " errors"
    end
    if STATE.match_cnt == 0 then
        msg = msg .. " | " .. STATE.path
    end
    return msg
end

return M
