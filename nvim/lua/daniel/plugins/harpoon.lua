return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "IVSOP/sidebar-harpoon.nvim" },
    config = function ()
        local harpoon = require("harpoon")
		local sbh = require("sidebar-harpoon")

		local function display(list)
			sbh.display(list:display())
		end

		local function add()
			local list = harpoon:list():add()
			display(list)
		end

		local function remove()
			local list = harpoon:list():remove()
			display(list)
		end

		local function select(number)
			local list = harpoon:list()
			list:select(number)
			sbh.select(number)
			display(list)
		end

		local function clear()
			local list = harpoon:list():clear()
			display(list)
		end

		display(harpoon:list())

        -- REQUIRED
        harpoon:setup()
        -- REQUIRED

        vim.keymap.set("n", "<leader>a", function() add() end)
        vim.keymap.set("n", "<leader>r", function() remove() end)
        vim.keymap.set("n", "<leader>x", function() clear() end)

        vim.keymap.set("n", "<leader>1", function() select(1) end)
        vim.keymap.set("n", "<leader>2", function() select(2) end)
        vim.keymap.set("n", "<leader>3", function() select(3) end)
        vim.keymap.set("n", "<leader>4", function() select(4) end)
        vim.keymap.set("n", "<leader>5", function() select(5) end)
        vim.keymap.set("n", "<leader>6", function() select(6) end)
        vim.keymap.set("n", "<leader>7", function() select(7) end)
        vim.keymap.set("n", "<leader>8", function() select(8) end)

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)

        -- basic telescope configuration
        local conf = require("telescope.config").values
        local function toggle_telescope(harpoon_files)
            local file_paths = {}
            for _, item in ipairs(harpoon_files.items) do
                table.insert(file_paths, item.value)
            end

            require("telescope.pickers").new({}, {
                prompt_title = "Harpoon",
                finder = require("telescope.finders").new_table({
                    results = file_paths,
                }),
                previewer = conf.file_previewer({}),
                sorter = conf.generic_sorter({}),
            }):find()
        end

        vim.keymap.set("n", "<leader>e", function() toggle_telescope(harpoon:list()) end,
            { desc = "Open harpoon window" })

    end
}
