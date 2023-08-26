# nvim-rgflow.lua

Work in progress. Just need to clean up and write docs/readme/screenies. Refer to docs/

- 
- I can never remember include/exclude globs, this helps.
- Autocomplete args.

## Installation

With `Vim-Plug':
```
:Plug 'mangelozzi/nvim-rgflow.lua'
```

## Customize

## Contributing
PR's are welcome!

## License

Copyright (c) Michael Angelozzi.  Distributed under the same terms as Neovim
itself. See `:help license`.

- The search is asyc so it doesnt block.
- However When populating the quickfix list, this code cannot be async. To make it appear none block, results are added in batches of 1000 with defering inbetween. 
