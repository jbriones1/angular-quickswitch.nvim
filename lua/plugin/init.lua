local M = {}

local ngRegex = {
  "%.component%.html$",
  "%.component%.s?[ac]ss$",
  "%.component%.ts$",
  "%.component%.spec.ts$",
  "%.directive%.ts$",
  "%.guard%.ts$",
  "%.service%.ts$",
  "%.pipe%.ts$",
  "%.directive%.spec%.ts$",
  "%.guard%.spec%.ts$",
  "%.service%.spec%.ts$",
  "%.pipe%.spec%.ts$",
}

--- Determines if this is an Angular file
---@param path string Full path of the file
---@return boolean
local function is_ng(path)
    for _, ext in ipairs(ngRegex) do
        if string.match(path, ext) then
            return true
        end
    end
    return false
end

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
    for i = 1, 4 do
        if string.match(path, ngRegex[i]) then
            return true
        end
    end
    return false
end

--- Returns .css, .sass, or .scss of the Angular component
---@param path string Path of the file, with the extension removed (.spec included)
---@return string|nil
local function get_style_file(path)
    if not is_component(path) then
        print("Not a component")
        return nil
    end

    local style_exts = { ".css", ".scss", ".sass" }
    for _, ext in ipairs(style_exts) do
        local style_file = path .. ext
        local files = vim.fn.findfile(style_file)
        if #files > 0 then
            return files[1]
        end
    end

    print("No style file found")
    return nil
end

--- Opens the specified file.
---@param path string Full path of the file
---@param type string Type of file to open: `class`, `template`, `test` or `style`
local function open_target_file(path, type)
    local file_to_open = nil
    if is_spec(path) then
        path = vim.fn.fnamemodify(path, ":r")
    end
    path = vim.fn.fnamemodify(path, ":r")
    if type == "class" then
        file_to_open = path .. ".ts"
    elseif type == "template" then
        file_to_open = path .. ".html"
    elseif type == "test" then
        file_to_open = path .. ".spec.ts"
    elseif type == "style" then
        file_to_open = get_style_file(path)
    end

    if file_to_open == nil then
        print("Unknown target file")
        return
    end

    vim.cmd.edit(file_to_open)
end

function M.quick_switch_toggle()
    local path = vim.fn.expand("%:p")
    if not is_ng(path) then
        print("Not an Angular file")
        return
    end
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
    local path = vim.fn.expand("%:p")
    if not is_ng(path) then
        print("Not an Angular file")
        return
    end
    local ext = vim.fn.fnamemodify(path, ":e")
    if ext == "ts" and not is_spec(path) then
        return
    end
    open_target_file(path, "class")
end

function M.quick_switch_template()
    local path = vim.fn.expand("%:p")
    if not is_ng(path) then
        print("Not an Angular file")
        return
    end
    local ext = vim.fn.fnamemodify(path, ":e")
    if ext == "html" then
        return
    end
    open_target_file(path, "template")
end

function M.quick_switch_style()
    local path = vim.fn.expand("%:p")
    if not is_ng(path) then
        print("Not an Angular file")
        return
    end
    local ext = vim.fn.fnamemodify(path, ":e")
    if string.match(ext, "s?[ac]ss") then
        return
    end
    open_target_file(path, "style")
end

function M.quick_switch_test()
    local path = vim.fn.expand("%:p")
    if not is_ng(path) then
        print("Not an Angular file")
        return
    end
    if is_spec(path) then
        return
    end
    open_target_file(path, "test")
end

function M.setup(opts)
    opts = opts or {}

    vim.api.nvim_create_user_command("NgQuickSwitchToggle", M.quick_switch_toggle, {})
    vim.api.nvim_create_user_command("NgQuickSwitchClass", M.quick_switch_class, {})
    vim.api.nvim_create_user_command("NgQuickSwitchTemplate", M.quick_switch_template, {})
    vim.api.nvim_create_user_command("NgQuickSwitchSpec", M.quick_switch_test, {})

    if opts.use_default_keymaps then
        vim.keymap.set("n", "<leader>qs", ":NgQuickSwitchToggle<cr>")
    end
end

return M
