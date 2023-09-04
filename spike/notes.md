Debug like this:
lua dofile('/home/michael/.config/nvim/tmp/rgflow.nvim/lua/rgflow/init.lua')

PROGRAM EXECUTION
-----------------
M.open_ui() -> .. start_from_ui mapped to hotkey() -> search()


rgflow.start_via_hotkey()
  or
rgflow.start_with_args()
  then -> start_ui() -> wait for <CR> or <ESC>

If <ESC> then -> rgflow.abort()
If <CR>  then -> rgflow.start() -> get_config()
                                -> spawn_job -> on_stdout()
                                -> on_stderr()
                                -> on_exit()

Neovim 0.10 uses Lua 5.1, can ignore the unpack warnings
:lua print (_VERSION) -- prints Lua 5.1

COMMON ARGUMENTS
----------------
@param mode - The vim mode, eg. "n", "v", "V", "^V", recommend calling this
function with visualmode() as this argument.
@param err and data - refer to https://github.com/luvit/luv/blob/master/docs.md#uvspawnpath-options-on_exit

Helpful
-------
To see contents of a table use: vim.print(table)

TODO
- When altering color palette (Alt-1 ALT-2) it messes up the color highlighting (match add in setup windows)
- Before opening an new rgflow window, check if one is already open
- Investigate &buftype = prompt
= remove invisible markers, and save location in a list, so one can search
  in the quick fix list and not get surprising results.
cdo / cfdo update
https://github.com/thinca/vim-qfreplace/blob/master/autoload/qfreplace.vim
-> not easy in rgflow type window, disable undo passed certain point

docs

Mark preview hints appear to left on window, at moment its next to the
suggested word, refer to:
:h previewheight
:h completeopt

hotkeys:
    CTRL+N or CTRL+P or TAB triggers line appropiate auto complete

```lua
--- Adds a method to the table class to check if an @element is within @table.
-- @return true if the element is within the table,  else return false
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
```
