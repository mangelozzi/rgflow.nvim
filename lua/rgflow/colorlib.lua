local M = {}

-- Function to convert RGB values to a hexadecimal color code
local function rgb_to_hex(r, g, b)
    -- Ensure the input values are within the valid range [0, 255]
    r = math.min(255, math.max(0, r))
    g = math.min(255, math.max(0, g))
    b = math.min(255, math.max(0, b))

    -- Convert RGB values to hexadecimal format
    local hex = string.format("#%02X%02X%02X", r, g, b)

    return hex
end

local function hex_to_rgb(hex_color)
    -- Remove the '#' if present in the color string
    local color_clean = hex_color:gsub("#", "")
    -- Convert the color string to a table of RGB values
    local r = tonumber(color_clean:sub(1, 2), 16) / 255
    local g = tonumber(color_clean:sub(3, 4), 16) / 255
    local b = tonumber(color_clean:sub(5, 6), 16) / 255
    return r, g, b
end

local function band(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end
local function rshift(a, b)
    return math.floor(a / 2 ^ b)
end
-- Function to convert a 24-bit color value to its R, G, and B components
local function bit24_to_rgb(color_value)
    local r = rshift(band(color_value, 0xFF0000), 16)
    local g = rshift(band(color_value, 0x00FF00), 8)
    local b = band(color_value, 0x0000FF)
    return r, g, b
end

function M.get_hi_group_exists(ns_id, name)
    local group_info = vim.api.nvim_get_hl(ns_id, {name = name})
    -- next will return nil if an empty dict, else a value
    return next(group_info)
end

function M.get_group_fg(ns_id, group_name)
    return vim.api.nvim_get_hl(ns_id, {name = group_name}).fg
end
function M.get_group_fg_as_rgb(ns_id, group_name)
    local bit24 = M.get_group_fg(ns_id, group_name)
    return bit24_to_rgb(bit24)
end
function M.get_group_fg_as_hex(ns_id, group_name)
    local r, g, b = M.get_group_fg_as_rgb(ns_id, group_name)
    return rgb_to_hex(r, g, b)
end

function M.get_group_bg(ns_id, group_name)
    return vim.api.nvim_get_hl(ns_id, {name = group_name}).bg
end
function M.get_group_bg_as_rgb(ns_id, group_name)
    local bit24 = M.get_group_bg(ns_id, group_name)
    return bit24_to_rgb(bit24)
end
function M.get_group_bg_as_hex(ns_id, group_name)
    local r, g, b = M.get_group_bg_as_rgb(ns_id, group_name)
    return rgb_to_hex(r, g, b)
end

-- local function get_is_bright_color(r,g,b)
--     local luminance = 0.299 * r + 0.587 * g + 0.114 * b
--     local threshold = 0.5
--     -- Compare luminance to the threshold
--     return luminance >= threshold
-- end

-- Function to check if a color is light or dark
local function get_is_light(r, g, b)
    local uicolors = {r / 255, g / 255, b / 255}
    local c = {}
    for _, col in ipairs(uicolors) do
        if col <= 0.03928 then
            table.insert(c, col / 12.92)
        else
            table.insert(c, math.pow((col + 0.055) / 1.055, 2.4))
        end
    end
    local L = 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
    local isLightColor = L > 0.179
    return isLightColor
end

-- If for_white is true, make the color dark
-- If for_white is false, make the color light
function M.auto_adjust_contrast(r, g, b, for_white)
    local is_light = get_is_light(r, g, b)
    if is_light ~= for_white then
        -- It is already a contrasting color, return it as is
        return r, g, b
    end
    local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    -- Not enough contrast so adjust it
    -- Calculate the relative luminance of the opposite color (black or white)
    local opposite_luminance = for_white and 0.25 or 0.75
    local factor = opposite_luminance / luminance
    factor = math.min(3.0, math.max(0.2, factor))
    local ro = math.floor(math.min(255, math.max(0, r * factor)))
    local go = math.floor(math.min(255, math.max(0, g * factor)))
    local bo = math.floor(math.min(255, math.max(0, b * factor)))
    return ro, go, bo
end

function M.get_contrasting_by_rgb(r, g, b, for_white)
    local is_input_light = get_is_light(r, g, b)
    return M.auto_adjust_contrast(r, g, b, for_white)
end

-- Change hex color to contrasting on white/black if for_white is true/false
function M.get_contrasting_by_hex(hex, for_white)
    local r, g, b = hex_to_rgb(hex)
    local r2, g2, b2 = M.get_contrasting_by_rgb(r, g, b, for_white)
    return rgb_to_hex(r2, g2, b2)
end

-- Change color fg from group_name to contrasting on white/black if for_white is true/false
function M.get_contrasting_by_group(ns_id, group_name, for_white)
    local input_24bit = vim.api.nvim_get_hl(ns_id, {name = group_name}).fg
    local r, g, b = bit24_to_rgb(input_24bit)
    local r2, g2, b2 = M.get_contrasting_by_rgb(r, g, b, for_white)
    return rgb_to_hex(r2, g2, b2)
end

function M.get_is_normal_fg_bright()
    local normal_def = vim.api.nvim_get_hl(0, {name = "Normal"})
    local r, g, b = bit24_to_rgb(normal_def.fg)
    return get_is_light(r, g, b)
end

function M.get_pattern_color(is_ui_light)
    return M.get_contrasting_by_group(0, "Title", is_ui_light)
    -- for _, group_name in pairs({'Title', 'Statement', 'Identifier'}) do
    --     if M.get_hi_group_exists(0, group_name) then
    --         return M.get_contrasting_by_group(0, group_name, is_ui_light)
    --     end
    -- end
    -- return M.get_contrasting_by_rgb(255,255,0, is_ui_light)
end

return M
