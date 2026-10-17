return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  init = function()
    -- Paste a register into the Claude terminal, like i_CTRL-R in insert mode.
    -- e.g. yank a selection with `y`, focus the terminal, then <C-r>" to paste it.
    vim.keymap.set("t", "<C-r>", function()
      local reg = vim.fn.nr2char(vim.fn.getchar())
      return '<C-\\><C-n>"' .. reg .. "pi"
    end, { expr = true, desc = "Paste register into terminal" })

    -- <C-;> moves focus between the code and the Claude chat pane (not open/close).
    -- Ask the plugin for its real terminal buffers so we never mis-detect and
    -- accidentally toggle (close) the window.
    local function claude_bufs()
      local set = {}
      local ok, cc = pcall(require, "claude-code")
      if ok and cc.claude_code and type(cc.claude_code.instances) == "table" then
        for _, buf in pairs(cc.claude_code.instances) do
          if type(buf) == "number" and vim.api.nvim_buf_is_valid(buf) then
            set[buf] = true
          end
        end
      end
      return set
    end

    local function focus_claude()
      local bufs = claude_bufs()
      if bufs[vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())] then
        vim.cmd("wincmd p") -- from chat -> back to code
        return
      end
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if bufs[vim.api.nvim_win_get_buf(win)] then
          vim.api.nvim_set_current_win(win)
          vim.cmd("startinsert")
          return
        end
      end
      vim.cmd("ClaudeCode") -- no visible chat pane -> open it
    end

    -- Hide numbers/signcolumn only in the Claude terminal window itself, so the
    -- editor keeps its line numbers.
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(args)
        if vim.api.nvim_buf_get_name(args.buf):match("claude") then
          vim.wo.number = false
          vim.wo.relativenumber = false
          vim.wo.signcolumn = "no"
        end
      end,
    })

    vim.keymap.set("n", "<C-;>", focus_claude, { desc = "Focus Claude chat/code" })
    vim.keymap.set("t", "<C-;>", function()
      vim.cmd("stopinsert")
      focus_claude()
    end, { desc = "Focus Claude chat/code" })
  end,
  opts = {
    window = {
      split_ratio = 0.3,
      position = "botright vertical",
      enter_insert = true,
      -- Let our TermOpen autocmd hide these instead; the plugin's own call can
      -- leak onto the editor window and strip its line numbers.
      hide_numbers = false,
      hide_signcolumn = false,
    },
    git = {
      use_git_root = true,
    },
    command = "claude",
    command_variants = {
      continue = "--continue",
      resume = "--resume",
      verbose = "--verbose",
    },
    keymaps = {
      toggle = {
        -- Focus-switching is handled by our own <C-;> mapping in init().
        normal = false,
        terminal = false,
        variants = {
          continue = "<leader>cC",
          verbose = "<leader>cV",
        },
      },
      window_navigation = true,
      scrolling = true,
    },
  },
}
