local get_settings = require("rgflow.settingslib").get_settings

local function apply_mappings()
    local mappings = get_settings().mappings
    for mode, mode_mappings in pairs(mappings) do
        for keymap, func_name in pairs(mode_mappings) do
            if string.sub(func_name, 1, 5) ~= "open_" then
                -- Only map keymaps for when rgflow is open, i.e. file type rgflow
                vim.keymap.set(
                    mode,
                    keymap,
                    require("rgflow")[func_name],
                    {noremap = true, buffer = true, silent = true}
                )
            end
        end
    end
end

apply_mappings()
