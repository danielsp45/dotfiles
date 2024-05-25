local M = {}

function M.cowboy()
	---@type table?
	local id
	local ok = true
	for _, key in ipairs({ " " }) do
		local count = 0
		local timer = assert(vim.loop.new_timer())
		local map = key
		vim.keymap.set("i", key, function()
			if vim.v.count > 0 then
				count = 0
			end
			if count == 1 then
        print("count == 1")
        vim.defer_fn(function()
            local buf = vim.api.nvim_get_current_buf()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_text(buf, row - 1, col - 1, row - 1, col - 1, {"."})
        end, 0)
        count = 0
			else
				count = count + 1
				timer:start(500, 0, function()
					count = 0
				end)
				return map
			end
		end, { expr = true, silent = true })
	end
end

return M
