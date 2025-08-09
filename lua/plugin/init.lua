local M = {}

local ngRegex = ".(spec.ts|html|scss|sass|css|ts)$"

--- Determines if the file is a test/spec file.
---@param path string Full path of the file
---@return boolean
local function is_spec(path)
    return string.match(path, "%.spec.%ts$")
end

--- Determines if the file is a component.
---@param path string Full path of the file
---@return boolean
local function is_component(path)
    return string.match(path, "%.component" .. ngRegex)
end

--- Returns .css, .sass, or .scss of the Angular component
---@param path string Full path of the file
---@return string|nil
local function get_style_file(path)
    if not string.match(path, "%.component" .. ngRegex) then
        error(": not a component", 1)
        return nil
    end

    local style_exts = { "css", "scss", "sass" }
    for _, ext in ipairs(style_exts) do
        local style_file = string.gsub(path, ngRegex, ext)
        local files = vim.fn.findfile(style_file)
        if #files > 0 then
            return files[1]
        end
    end

    error(": no style file found", 1)
    return nil
end

--- Opens the specified file.
---@param path string Full path of the file
---@param type string Type of file to open: `class`, `template`, `test` or `style`
local function open_target_file(path, type)
    local file_to_open = nil
    if type == "class" then
        file_to_open = string.gsub(path, ngRegex, ".ts")
    elseif type == "template" then
        file_to_open = string.gsub(path, ngRegex, ".html")
    elseif type == "test" then
        file_to_open = string.gsub(path, ngRegex, ".spec.ts")
    elseif type == "style" then
        file_to_open = get_style_file(path)
    end

    if file_to_open == nil then
        error(": unknown target file", 1)
        return
    end

    vim.cmd.edit(file_to_open)
end

function M.quick_switch_toggle()
    local path = vim.fn.expand("%:p")
    -- Default is the class file
    local file_type = "class"
    local ext = vim.fn.fnamemodify(path, ":e")

    if ext == "ts" then
        -- If it's the class file for a component, go to the template
        if is_component(path) and not is_spec(path) then
            type = "template"
        -- If it's a class file for anything else, go to the test file
        elseif not is_spec(path) then
            type = "test"
        end
    end
    open_target_file(path, file_type)
end

function M.quick_switch_class()
    open_target_file(vim.fn.expand("%:p"), "class")
end

function M.quick_switch_template()
    open_target_file(vim.fn.expand("%:p"), "template")
end

function M.quick_switch_style()
    open_target_file(vim.fn.expand("%:p"), "style")
end

function M.quick_switch_test()
    open_target_file(vim.fn.expand("%:p"), "test")
end

function M.setup(opts)
    opts = opts or {}

    vim.api.nvim_create_user_command("NgQuickSwitchToggle", M.quick_switch_toggle, {})
    vim.api.nvim_create_user_command("NgQuickSwitchClass", M.quick_switch_class, {})
    vim.api.nvim_create_user_command("NgQuickSwitchTemplate", M.quick_switch_template, {})
    vim.api.nvim_create_user_command("NgQuickSwitchTest", M.quick_switch_test, {})

    if opts.use_default_keymaps then
        vim.keymap.set("n", "<leader>qs", ":NgQuickSwitchToggle<cr>")
    end
end

return M
