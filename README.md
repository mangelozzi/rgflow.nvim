# rgflow.nvim

- I can never remember include/exclude globs, this helps.
- Autocomplete args.

Get in the flow with RipGrep. Not simply a wrapper which could be replaced by a
few lines of config.

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
    - You can set it's theme colours. However if you are someone you likes to 
      change color scheme a lot, if you use the defaults they will update to 
      some sane defaults based on the applied scheme.

## Intro

## Installation

With `Vim-Plug':
```
:Plug 'mangelozzi/nvim-rgflow.lua'
```
## Setup


## Contributing
PR's are welcome!

## License

Copyright (c) Michael Angelozzi.  Distributed under the same terms as Neovim
itself. See `:help license`.
