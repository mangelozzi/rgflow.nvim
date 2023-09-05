# rgflow.nvim

Get in the flow with RipGrep. Not simply a wrapper which could be replaced by a
few lines of config.

Essence of the plugin:

<img src="https://user-images.githubusercontent.com/19764314/265692852-9f070779-3f0e-441e-be61-812eb0cd0dfe.gif">

Showing more of the features:

<img src="https://user-images.githubusercontent.com/19764314/265692891-cd2f5f49-fe2c-4e29-baee-816453976ff0.gif">


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

### Configuration options


For the full list of configurable settings refer to [Default settings](https://github.com/mangelozzi/rgflow.nvim/blob/master/lua/rgflow/defaults.lua)

```lua
local my_settings = {
    -- For some reason --no-messages makes it stop working
    -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
    cmd_flags = "--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore --ignore -M 500",
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

