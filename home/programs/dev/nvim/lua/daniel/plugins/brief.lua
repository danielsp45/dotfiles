return {
  "danielsp45/brief.nvim",
  dev = true,
  cmd = "Brief",
  keys = {
    { "<leader>B", "<cmd>Brief<cr>", desc = "Toggle the brief panel" },
    { "<leader>C", "<cmd>Brief edit<cr>", mode = "x", desc = "Edit the selection with Claude" },
  },
  opts = {},
}
