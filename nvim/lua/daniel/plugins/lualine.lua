local components = {
    lsp = {
        function()
            local buf_clients = vim.lsp.get_active_clients { bufnr = 0 }
            if #buf_clients == 0 then
                return "LSP Inactive"
            end

            local buf_client_names = {}
            local copilot_active = false

            -- add client
            for _, client in pairs(buf_clients) do
                if client.name ~= "null-ls" and client.name ~= "copilot" then
                    if client.name == "GitHub Copilot" then
                        copilot_active = true
                    else
                        table.insert(buf_client_names, client.name)
                    end
                end
            end

            local unique_client_names = table.concat(buf_client_names, ", ")
            local language_servers = string.format("[%s]", unique_client_names)

            if copilot_active then
                language_servers = language_servers .. "  "
            end

            return language_servers
        end,
        color = { gui = "bold" },
    },
    filepath = {
        -- Get the filepath of the current buffer from the directory where nvim was started
        function()
            local path = vim.fn.expand "%:p"
            local home = os.getenv "HOME"
            if string.find(path, home) then
                path = string.gsub(path, home, "~")
            end
            return path
        end,
    },
    filetype = {
        "filetype", cond = nil, padding = { left = 1, right = 1 },
    },
    scrollbar = {
        function()
            local current_line = vim.fn.line "."
            local total_lines = vim.fn.line "$"
            local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
            local line_ratio = current_line / total_lines
            local index = math.ceil(line_ratio * #chars)
            return chars[index]
        end,
        padding = { left = 0, right = 0 },
        color = "SLProgress",
        cond = nil,
    },
}

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'gruvbox',
                component_separators = { left = ' ', right = ' '},
                section_separators = { left = '', right = ''},
                disabled_filetypes = {
                    statusline = {},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                }
            },
            sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'filename'},
                lualine_x = {components.lsp, components.filetype},
                lualine_y = {'progress'},
                lualine_z = {'location'}
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {'filename'},
                lualine_x = {'location'},
                lualine_y = {},
                lualine_z = {}
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {}
        }
    end,
}
