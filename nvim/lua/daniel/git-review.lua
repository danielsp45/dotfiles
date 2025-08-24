-- lua/git_diff_picker.lua
local pickers    = require("telescope.pickers")
local finders    = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf       = require("telescope.config").values
local themes     = require("telescope.themes")

local function shell(cmd)
  -- Run command in login shell so $PATH etc. are respected
  return { "bash", "-lc", cmd }
end

local function mk_picker(args)
  args = args or "" -- e.g. "--staged", "HEAD~1..HEAD", etc.

  pickers.new(
    themes.get_dropdown({
      previewer = true, -- floating window w/ preview
      layout_config = { width = 0.95, height = 0.85 },
    }),
    {
      prompt_title = "git diff " .. (args ~= "" and args or "(working tree)"),
      finder = finders.new_oneshot_job(
        shell("git diff " .. args .. " --name-only"),
        {
          entry_maker = function(line)
            return { value = line, display = line, ordinal = line }
          end,
        }
      ),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          -- Use ANSI colors in preview, like your fzf command
          local file = vim.fn.fnameescape(entry.value)
          local cmd  = "git diff " .. args .. " --color=always -- " .. file
          -- Optional: if you have `delta`, uncomment to get nicer diffs:
          -- cmd = cmd .. " | delta"
          return shell(cmd)
        end,
      }),
    }
  ):find()
end

-- Expose as a Lua function you can require and call
local M = {}
M.open = mk_picker

-- :GitDiffPick [args...] -> forwards args to `git diff`
vim.api.nvim_create_user_command("GitDiffPick", function(opts)
  mk_picker(table.concat(opts.fargs, " "))
end, {
  nargs = "*",
  complete = function()
    -- rudimentary completion for common flags; you can expand this
    return { "--staged", "--cached" }
  end
})

return M
