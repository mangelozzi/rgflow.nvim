# nvim-rgflow.lua

Work in progress. Just need to clean up and write docs/readme/screenies. Refer to docs/

- 
- I can never remember include/exclude globs, this helps.
- Autocomplete args.

## Why

- Main purpose: Perform a [RipGrep](https://github.com/BurntSushi/ripgrep) 
  with interface that is very close to the CLI, yet intuitive, and place those results in the QuickFix list
- Additional benefits are:
    - QuickFix results features:
        - Delete result operator, e.g. `dd`, or `3dj` and friends
        - Mark/unmark results operator, e.g. `<TAB>` to mark a result (can be marked more than once),
          and `<S-TAB>` to unmark a result.

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

- The search is asyc so it doesnt block.
- However When populating the quickfix list, this code cannot be async. To make it appear none block, results are added in batches of 1000 with defering inbetween. 
