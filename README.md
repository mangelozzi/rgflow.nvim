# rgflow.nvim

Get in the flow with RipGrep. Not simply a wrapper which could be replaced by a
few lines of config.

<img src="https://user-images.githubusercontent.com/19764314/265533036-f05ff0cd-8b4f-4c71-8730-0bb56de9e318.gif">


## Why

- Main purpose: Perform a [RipGrep](https://github.com/BurntSushi/ripgrep) 
  with interface that is very close to the CLI, yet intuitive, and place those
  results in the QuickFix list
    - The more you use this plugin, the better you should become at using
      RipGrep from the CLI.
      
- Additional features:
    - QuickFix:
        - Delete results operator, e.g. `dd`, or `3dj` and friends
        - Mark/unmark results operator, e.g. `<TAB>` to mark a result (can be marked more than once),
          and `<S-TAB>` to unmark a result.
        - The operators also have a visual range counter variants.
    - RipGrep flags/options auto complete.
    - Bring up RipGrep help in a buffer, so you can navigate/search it Vim style.
    - Find search results asynchronously
    - Populates the QuickFix windows in batches so it seems like it's none blocking.
    - Highlights the search term, so even if `:noh` the search terms are still highlighted
        - Even if used a regex as the search term
    - You can set it's theme colours. However if you are someone you likes to 
      change color scheme a lot, if you use the defaults they will update to 
      some sane defaults based on the applied scheme.

- I can never remember include/exclude globs, this helps.
    - Also has autocomplete for RipGrep flags/options with descriptions

## Intro

## Installation

Use your favourite plugin manager, e.g. with [Packer](https://github.com/wbthomason/packer.nvim):

```Lua
use("mangelozzi/nvim-rgflow.lua")
```

## Setup

The parameter of most interest is probably `cmd_flags`. You could modify it like this:

```lua
cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",
require('rgflow').setup(
    {
        cmd_flags = cmd_flags
    }
)
```

- The reason it contains opposing settings, is because then one just deletes options as required
- Since the later option "wins", deleting `--ignore` will make the `--no-ignore` flag take effect

### All configuration options

```lua
local defaults = {
    -- For some reason --no-messages makes it stop working
    -- seprated by a space
    -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
    cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",

    -- After a search, whether to set incsearch to be the pattern searched for
    incsearch_after = true,

    -- ui_top_line_char = "▄",
    --  Example chars: ━━━ ═══ ███  ▀▀▀ ▃▃▃   
    ui_top_line_char = "▃",

    -- The vim `completeopt` for when using autocomplete with the RgFlow UI open
    completeopt = "menuone,noinsert,noselect",

    mappings = {
        -- Mappings that all always present
        trigger = {
            n = {
                ["<leader>rG"] = "open_blank", -- open UI - search pattern = blank
                ["<leader>rg"] = "open_cword", -- open UI - search pattern = <cword>
                ["<leader>rp"] = "open_paste", -- open UI - search pattern = First line of unnamed register as the search pattern
                ["<leader>ra"] = "open_again", -- open UI - search pattern = Previous search pattern
                ["<leader>rx"] = "abort",      -- close UI / abort searching / abortadding results
                ["<leader>rc"] = "print_cmd",  -- Print a version of last run rip grep that can be pasted into a shell
            },
            x = {
                ["<leader>rg"] = "open_visual", -- open UI - search pattern = current visual selection
            },
        },
        -- Mappings that are local only to the RgFlow UI
        ui = {
            n = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters
                ["<ESC>"] = "close", -- With the ui open, disgard and close the UI window
                ["?"]     = "show_rg_help", -- Show the rg help in a floating window
                ["<BS>"]  = "nop",   -- No operation
                ["<C-^>"] = "nop",   -- No operation
                ["<C-6>"] = "nop",   -- No operation
            },
            i = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters (from insert mode)
                ["<TAB>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-N>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-P>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
            },
        },
        -- Mapping that are local only to the QuickFix window
        quickfix = {
            n = {
                ["d"] = "qf_delete",
                ["dd"] = "qf_delete_line",
                ["<TAB>"] = "qf_mark",
                ["<S-TAB>"] = "qf_unmark",
                ["<BS>"]  = "nop", -- No operation
                ["<C-^>"] = "nop", -- No operation
                ["<C-6>"] = "nop", -- No operation
            },
            x = {
                ["d"] = "qf_delete_visual",
                ["<TAB>"] = "qf_mark_visual",
                ["<S-TAB>"] = "qf_unmark_visual",
            }
        },
    },

    quickfix = {
        -- Whether to use `set relativenumber`
        -- Quickfix window - Whether to show relative numbers
        relative_number = false,

        -- Quickfix window - Whether to wrap text
        wrap = false,

        -- Quickfix window - Blank string to not show color_column, or column number to set it at a certain width
        color_column = "",

        -- String to prepend when marking an entry in the quick fix
        mark_str = "▌",

        -- Open the quickfix window automatically after a serach
        open_qf_list = true,

        -- The QF window is set to the height of the number of matches, but bounded
        -- to be between a min of 3 and a max of this variable:
        max_height_lines = 7,

        -- By default a new search will create a search list after the current qf list
        -- Any lists afterwards will be lost
        -- Set to true such that if you navigate to older qf list with :colder, then
        -- starting a new list will append it after :clast
        new_list_always_appended = false,

        -- Disable CTRL+^ and CTRL + SHIFT + ^ to jump to alt file
        -- Generally don't wish to switch to an alt file within the small QF window
        disable_edit_alt_file = true,
    },

    colors = {
        -- The default colors are calculated from some sane values that depend
        -- on your current color scheme.

        -- The values map to vim.api.nvim_set_hl {val} parameters, see :h nvim_set_hl
        -- Examples:
        --      RgFlowInputPath    = {fg = "fg", bg="#1234FF", bold=true}
        --      RgFlowInputPattern = {link = "Title"}
        ---- UI
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowHead          = nil,
        RgFlowHeadLine      = nil,
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg       = nil,
        RgFlowInputFlags    = nil,
        RgFlowInputPattern  = nil,
        RgFlowInputPath     = nil,
        ---- Quickfix
        RgFlowQfPattern     = nil,
    },
}

local func_name_to_keymap_opts = {
    open_again       = { noremap = true, silent = true },
    open_blank       = { noremap = true, silent = true },
    open_cword       = { noremap = true, silent = true },
    open_paste       = { noremap = true, silent = true },
    open_visual      = { noremap = true, silent = true },
    abort            = { noremap = true, silent = true },
    print_cmd        = { noremap = true, silent = true },

    auto_complete    = { noremap = true, silent = true, buffer = true, expr = true },
    start            = { noremap = true, silent = true, buffer = true },
    close            = { noremap = true, silent = true, buffer = true },
    show_rg_help     = { noremap = true, silent = true, buffer = true },
    nop              = { noremap = true, silent = true, buffer = true },

    qf_delete        = { noremap = true, silent = true, buffer = true },
    qf_delete_line   = { noremap = true, silent = true, buffer = true },
    qf_delete_visual = { noremap = true, silent = true, buffer = true },
    qf_mark          = { noremap = true, silent = true, buffer = true },
    qf_mark_visual   = { noremap = true, silent = true, buffer = true },
    qf_unmark        = { noremap = true, silent = true, buffer = true },
    qf_unmark_visual = { noremap = true, silent = true, buffer = true },
}

require('rgflow').setup(my_settings)
```

For example this is my personnel settings:
```lua
-- file ~/.config/nvim/after/plugin/rgflow.lua
require("rgflow").setup(
    {
        cmd_flags = ("--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore -M 500"
            .. " -g !**/static/*/jsapp/"
            .. " -g !**/static/*/wcapp/")
    }
)
```

## Contributing

PR's are welcome!

## License

Copyright (c) Michael Angelozzi.  Distributed under the same terms as Neovim
itself. See `:help license`.

