return {
    "Pocco81/auto-save.nvim",
    lazy = false,
	config = function()
		require("auto-save").setup {
            enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
            trigger_events = {"InsertLeave", "TextChanged"}, -- vim events that trigger auto-save. See :h events
            execution_message = {
                message = function() -- message to print on save
                    return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
                end,
                dim = 0.18, -- dim the color of `message`
                cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
            },
		}
	end,
}
