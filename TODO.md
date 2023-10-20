Cfilter and Cfilter! mess up the highlighting
From chat gpt:
```
Copy code
-- Define a function to be executed after :Cfilter
function! AfterCfilter()
    lua <<EOF
        -- Your Lua code here
        print("Cfilter command executed!")
    EOF
endfunction

-- Define an autocmd to trigger the function after :Cfilter
augroup CustomQuickFixCmd
    autocmd!
    autocmd QuickFixCmdPre cfilter call AfterCfilter()
augroup END
In this example, the AfterCfilter Vim function calls a Lua block where you can insert your Lua code. The QuickFixCmdPre event triggers the function before the :Cfilter command is executed. You can modify the AfterCfilter function to include any Lua code you want to run after the :Cfilter command. Remember to replace the print("Cfilter command executed!") line with your actual Lua code logic.
```

Make sure to place this configuration in your Neovim init.vim or init.lua file to enable this behavior.






- Hard to abort huge ass search, if pressed F4 before hand

-- For some reason --no-messages makes it stop working


- Add items to quickfix while searching, instead of in chunks
- show in brackets pattern while waitinf for searching


- Improve Readme with info from docs
- Fix highlighting
- Image - better image

- Detail gif show regex hilighting
