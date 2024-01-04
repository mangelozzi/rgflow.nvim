# rgflow.nvim

Get in the flow with RipGrep.
The more you use this plugin, the better you become at using RipGrep from the CLI.
Not simply a wrapper which could be replaced by a few lines of config.
It's a very simple to use tool aspiring to the Unix philosophy.

3 second intro:

<img src="https://github.com/mangelozzi/rgflow.nvim/assets/19764314/f75cd129-126b-457a-b9c5-ee5c14775069" alt="Core of what the plugin does">

Showing more of the features:

<img src="https://github.com/mangelozzi/rgflow.nvim/assets/19764314/7cace572-086b-46e9-94a5-0a70da0c941c" alt="Showing more details of the plugin">

## QuickStart Guide (TL;DR)

1. Ensure you have [RipGrep](https://github.com/BurntSushi/ripgrep) installed
2. Set your plugin manager to use `mangelozzi/nvim-rgflow.lua` and install the plugin.
3. Create a file for the configuration, e.g. `~/.config/nvim/after/plugin/rgflow.lua`
4. Paste in the minimal configuration code:
```lua
require('rgflow').setup(
    {
        -- Set the default rip grep flags and options for when running a search via
        -- RgFlow. Once changed via the UI, the previous search flags are used for 
        -- each subsequent search (until Neovim restarts).
        cmd_flags = "--smart-case --fixed-strings --ignore --max-columns 200",

        -- Mappings to trigger RgFlow functions
        default_trigger_mappings = true,
        -- These mappings are only active when the RgFlow UI (panel) is open
        default_ui_mappings = true,
        -- QuickFix window only mapping
        default_quickfix_mappings = true,
    }
)
```
5. After restarting Neovim, press `<leader>rg` to open the RgFlow UI
6. Type in a search pattern and press `<ENTER>`
7. A search will run and populate the QuickFix window
8. Press `dd` to delete a QuickFix entry, or select a visual range and press `d`
9. Press `TAB` to mark a line and `<S-TAB>` to unmark a line, a line can be marked more than once

If you like this plugin please give it a :star:!

Bonus note: Pressing `<TAB>` when the UI panel is open provides autocomplete for the line you are on (rip grep flags/cwords/filepaths)

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
    - Searches are appended to your command history, so you can easily repeat previous searches
        - E.g. `:<up>` 
- I can never remember include/exclude globs, this helps.
    - Also has autocomplete for RipGrep flags/options with descriptions
- Tested on Linux and Windows

## Installation

Use your favourite plugin manager, e.g. with [Packer](https://github.com/wbthomason/packer.nvim):

```Lua
use("mangelozzi/nvim-rgflow.lua")
```

And then `:PackerSync` etc. to install it.

## Setup

- For a minimal config refer to the Quick start guide.

### `cmd_flags`

- The parameter of most interest is probably `cmd_flags`
    - The default value is `cmd_flags = "--smart-case --fixed-strings --no-fixed-strings --no-ignore --ignore --max-columns 500"`
    - The reason it contains opposing settings (e.g. `--no-ignore` vs `--ignore`), is because then one can quickly deletes options as required
    - E.g. since the later option "wins", deleting `--ignore` will make the `--no-ignore` flag take effect

### Mappings

- By default RgFlow will not change your editors current behaviour or modify any mappings.
    - You have to opt in to use the default mappings

<details><summary>Default Mappings</summary>

```lua
    mappings = {
        trigger = {
            -- Normal mode maps
            n = {
                ["<leader>rG"] = "open_blank", -- open UI - search pattern = blank
                ["<leader>rg"] = "open_cword", -- open UI - search pattern = <cword>
                ["<leader>rp"] = "open_paste", -- open UI - search pattern = First line of unnamed register as the search pattern
                ["<leader>ra"] = "open_again", -- open UI - search pattern = Previous search pattern
                ["<leader>rx"] = "abort",      -- close UI / abort searching / abortadding results
                ["<leader>rc"] = "print_cmd",  -- Print a version of last run rip grep that can be pasted into a shell
                ["<leader>r?"] = "print_status",  -- Print info about the current state of rgflow (mostly useful for deving on rgflow) 
            },
            -- Visual/select mode maps
            x = {
                ["<leader>rg"] = "open_visual", -- open UI - search pattern = current visual selection
            },
        },
        -- Mappings that are local only to the RgFlow UI
        ui = {
            -- Normal mode maps
            n = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters
                ["<ESC>"] = "close", -- With the ui open, discard and close the UI window
                ["?"]     = "show_rg_help", -- Show the rg help in a floating window, which can be closed with q or <ESC> or the usual <C-W><C-C>
                ["<BS>"]  = "nop",   -- No operation
                ["<C-^>"] = "nop",   -- No operation
                ["<C-6>"] = "nop",   -- No operation
            },
            -- Insert mode maps i = {
                ["<CR>"]  = "start", -- With the ui open, start a search with the current parameters (from insert mode)
                ["<TAB>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-N>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
                ["<C-P>"] = "auto_complete", -- start autocomplete if PUM not visible, if visible use own hotkeys to select an option
            },
        },
        -- Mapping that are local only to the QuickFix window
        quickfix = {
            -- Normal
            n = {
                ["d"] = "qf_delete",        -- QuickFix normal mode delete operator
                ["dd"] = "qf_delete_line",  -- QuickFix delete a line from quickfix
                ["<TAB>"] = "qf_mark",      -- QuickFix mark a line in the quickfix
                ["<S-TAB>"] = "qf_unmark",  -- QuickFix unmark a line in the quickfix window
                ["<BS>"]  = "nop", -- No operation
                ["<C-^>"] = "nop", -- No operation - Probably don't want to switch to a buffer in the little quickfix window
                ["<C-6>"] = "nop", -- No operation
            },
            -- Visual/select mode maps
            x = {
                ["d"] = "qf_delete_visual",       -- QuickFix visual mode delete operator
                ["<TAB>"] = "qf_mark_visual",     -- QuickFix visual mode mark operator
                ["<S-TAB>"] = "qf_unmark_visual", -- QuickFix visual mode unmark operator
            }
        },
    }
```

</details>

### Full configuration options


For the full list of configurable settings refer to [Default settings](https://github.com/mangelozzi/rgflow.nvim/blob/master/lua/rgflow/defaults.lua)

### Example Config

This is my personnel configuration:

```lua
require("rgflow").setup(
    {
        default_trigger_mappings = true,
        default_ui_mappings = true,
        default_quickfix_mappings = true,

        -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
        cmd_flags = ("--smart-case -g *.{*,py} -g !*.{min.js,pyc} --fixed-strings --no-fixed-strings --no-ignore -M 500"
            -- Exclude globs
            .. " -g !**/.angular/"
            .. " -g !**/node_modules/"
            .. " -g !**/static/*/jsapp/"
            .. " -g !**/static/*/wcapp/"
        )
    }
)
```

## Lua Commands

- If you wish to create your own mappings, the below functions are provided.
- None of these commands require args except `setup` and `search`, however `open` can take optional args.

| **Command**                           | **Description**                                        |
|---------------------------------------|--------------------------------------------------------|
| `require('rgflow').setup(config)`     | Setup the plugin with the provided config settings
| `require('rgflow').open`              | Opens the UI with default arguments.<br>**Pattern** = blank<br>**Flags** = previous flags (or `cmd_flags` after startup)<br>**Path** = PWD
| `require('rgflow').open(pattern, flags, path, options)` | Open UI with specified args<br>e.g. `require('rgflow').open('foo', '--smart-case --ignore', '~/code/my_project')`<br>Refer to section `Open Options` below for more detail.
| `require('rgflow').open_blank`        | Open UI with blank search pattern (insert mode).
| `require('rgflow').open_cword`        | Open UI with current word as the search pattern.
| `require('rgflow').open_again`        | Open UI with previous search pattern.
| `require('rgflow').open_paste`        | Open UI with first line of unnamed register as pattern.
| `require('rgflow').open_visual`       | Open UI with current visual selection as pattern.
| `require('rgflow').start`             | Start searching with current UI parameters.
| `require('rgflow').close`             | Close the current UI window.
| `require('rgflow').search(pattern, flag, path)` | Execute search immediately with specified args.
| `require('rgflow').abort`             | Abort current operation (searching or adding results).
| `require('rgflow').show_rg_help`      | Show `rg --help` content in a popup window.
| `require('rgflow').nop`               | No operation, useful for disabling hotkeys.
| `require('rgflow').get_cmd`           | Get last run rip grep command.
| `require('rgflow').print_cmd`         | Print last run rip grep command.
| `require('rgflow').qf_apply_hl`       | After removing lines from the QF list by some means outside of RgFlow (e.g. `:Cfilter` or `:Cfilter!` command), one can sync the highlighting positions again.
| `require('rgflow').qf_delete`         | QuickFix normal mode delete operator.
| `require('rgflow').qf_delete_line`    | Delete a line from QuickFix.
| `require('rgflow').qf_delete_visual`  | QuickFix visual mode delete operator.
| `require('rgflow').qf_mark`           | QuickFix mark a line in the QuickFix window.
| `require('rgflow').qf_mark_visual`    | QuickFix visual mode mark operator.
| `require('rgflow').qf_unmark`         | QuickFix unmark a line in the QuickFix window.
| `require('rgflow').qf_unmark_visual`  | QuickFix visual mode unmark operator.
| `require('rgflow').auto_complete`     | Auto complete based on input box context.
| `require('rgflow').print_status`      | Print info about the current state of rgflow.

### Open Options

- The open function signature looks like this:
    - `require('rgflow').open(pattern, flags, path, options)`
- The `options` parameter is a lua table with the following keys (for now only one key):
    - `custom_start` 
        - Useful for using Rgflow's UI to gather the search info, then call one's own tool.
        - The parameter is a function that receives the pattern/flags/path (3 x strings) from UI, and performs it's own custom function, e.g. within a keymap:
        ```lua
        vim.keymap.set("n", "<leader>RG", function()
            -- Here we open UI with the default pattern/flags/path by passing in nil, nil, nil
            require('rgflow').open(nil, nil, nil, {
                custom_start = function(pattern, flags, path)
                    print('Pattern:'..pattern..' Flags:'..flags..' Path:'..path)
                end
            })
        end, {noremap = true})
        ```

## Bonus Tips

- This plugin compliments `:Cfilter` very well. 
    - `:Cfilter` is built into Vim/Neovim for filtering your QuickFix lists.
    - Although it comes with Neovim, it must first be enabled with: `vim.cmd('packadd cfilter')`
    - `:Cfilter foo` will limit your QuickFix results to only those that contain the phrase `foo`
    - `:Cfilter! foo` does the inverse, only those that **don't** contain `foo` are kept.
- By using `Cfilter` and this plugin's delete function, you can quickly massage your QuickFix list, making it ready to unleash a `:cdo` and `:cfdo` ... unlocking all sorts of super powers.
    - e.g. To substitute the word `foo` for `bar` on each QuickFix match then save the modified file:
        - `:cdo s/foo/bar/ | update`

## Contributing

PR's are welcome!

## License

Copyright (c) Michael Angelozzi.  Distributed under the same terms as Neovim
itself. See `:help license`.
