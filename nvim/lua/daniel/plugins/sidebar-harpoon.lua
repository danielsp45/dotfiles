return {
	-- dir = "/Users/danielsp_45/projects/sidebar-harpoon.nvim",
	"IVSOP/sidebar-harpoon.nvim",
    config = function ()
         local sbh = require("sidebar-harpoon")

         sbh.create()

         vim.keymap.set("n", "<S-n>", function() sbh.toggle() end)
         vim.keymap.set("n", "<leader>t", function() sbh.focus_toggle() print(sbh.is_focused) end)
    end
}
