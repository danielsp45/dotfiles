-- Side panel showing the notes in .ai/brief.md for the code under the cursor.
--
-- Brief format:
--   # src/buffer_pool.cc      file notes
--   ## BufferPool             class notes
--   ## BufferPool::evict      function notes
local M = {}

local BRIEF = ".ai/brief.md"
local WIDTH = 46

local cpp_scopes = {
  function_definition = true,
  class_specifier = true,
  struct_specifier = true,
  field_declaration = true, -- method declarations in a header
}

M.scope_types = { c = cpp_scopes, cpp = cpp_scopes }

local state = { key = nil, root = nil, cache = {} }

-- Parsing ---------------------------------------------------------------

local function clean_heading(text)
  return (text:gsub("`", ""):gsub("%(%)$", ""):gsub("^%./", ""))
end

function M.parse(lines)
  local brief = { files = {}, scopes = {} }
  local file, section
  local fenced = false

  for _, line in ipairs(lines) do
    if line:match("^%s*```") then
      fenced = not fenced
    end

    local h1 = not fenced and line:match("^#%s+(.-)%s*$")
    local h2 = not fenced and line:match("^##%s+(.-)%s*$")

    if h1 then
      file = clean_heading(h1)
      brief.files[file] = brief.files[file] or { lines = {}, scopes = {} }
      section = brief.files[file]
    elseif h2 and file then
      local name = clean_heading(h2)
      section = { file = file, name = name, lines = {} }
      brief.files[file].scopes[name] = section
      brief.scopes[name] = brief.scopes[name] or {}
      table.insert(brief.scopes[name], section)
    elseif section then
      table.insert(section.lines, line)
    end
  end

  return brief
end

-- Lookup ----------------------------------------------------------------

local function has_text(lines)
  for _, line in ipairs(lines) do
    if line:match("%S") then
      return true
    end
  end
  return false
end

local function stem(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

-- Most specific first: A::b, then the bare method name b, then A.
local function candidates(path)
  local bare = path:gsub("%b<>", "")
  local parts = vim.split(bare, "::", { plain = true, trimempty = true })
  local names = {}
  for i = #parts, 1, -1 do
    table.insert(names, table.concat(parts, "::", 1, i))
    if i == #parts and i > 1 then
      table.insert(names, parts[i])
    end
  end
  return names
end

-- A header and its source file share notes. Unqualified names only match
-- across files with the same stem, so that free functions don't collide.
local function find_scope(brief, file, name)
  local entry = brief.files[file]
  local own = entry and entry.scopes[name]
  if own and has_text(own.lines) then
    return own
  end

  local qualified = name:find("::", 1, true) ~= nil
  for _, section in ipairs(brief.scopes[name] or {}) do
    if has_text(section.lines) and (qualified or stem(section.file) == stem(file)) then
      return section
    end
  end
end

function M.lookup(brief, file, path)
  for _, name in ipairs(candidates(path)) do
    local section = find_scope(brief, file, name)
    if section then
      return { title = section.name, source = section.file, lines = section.lines }
    end
  end

  local entry = brief.files[file]
  if entry and has_text(entry.lines) then
    return { title = file, source = file, lines = entry.lines }
  end
end

-- Cursor scope ----------------------------------------------------------

local function scope_name(node, buf)
  local target = node:field("name")[1]
  if not target then
    local declarator = node:field("declarator")[1]
    while declarator and declarator:field("declarator")[1] do
      declarator = declarator:field("declarator")[1]
    end
    target = declarator
  end
  return target and vim.treesitter.get_node_text(target, buf)
end

-- Returns the scope under the cursor, such as "BufferPool::evict", and
-- whether the syntax tree currently has errors.
function M.scope_path()
  local buf = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local types = lang and M.scope_types[lang]
  if not types then
    return "", false
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return "", false
  end

  local tree = parser:parse()[1]
  local node = vim.treesitter.get_node({ bufnr = buf })
  local parts = {}
  while node do
    if types[node:type()] then
      local name = scope_name(node, buf)
      if name then
        table.insert(parts, 1, name)
      end
    end
    node = node:parent()
  end

  return table.concat(parts, "::"), tree ~= nil and tree:root():has_error()
end

-- Panel -----------------------------------------------------------------

local function is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function read_brief(root)
  local path = root .. "/" .. BRIEF
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end

  local stamp = stat.mtime.sec .. "." .. stat.mtime.nsec .. "." .. stat.size
  local cached = state.cache[path]
  if cached and cached.stamp == stamp then
    return cached.brief
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local brief = M.parse(lines)
  state.cache[path] = { stamp = stamp, brief = brief }
  return brief
end

local function set_lines(lines)
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function render(root, file, path)
  if not root then
    return set_lines({ "No " .. BRIEF .. " in this project" })
  end

  local brief = read_brief(root)
  if not brief then
    return set_lines({ "No " .. BRIEF .. " in this project" })
  end

  local note = file and M.lookup(brief, file, path)
  if not note then
    return set_lines({ "No notes for " .. (path ~= "" and path or file or "this file") })
  end

  local body = vim.deepcopy(note.lines)
  while body[1] and not body[1]:match("%S") do
    table.remove(body, 1)
  end
  while body[#body] and not body[#body]:match("%S") do
    table.remove(body)
  end

  local lines = { "# " .. note.title }
  if note.source ~= note.title then
    table.insert(lines, note.source)
  end
  table.insert(lines, "")
  vim.list_extend(lines, body)
  set_lines(lines)
end

local function stop_watching()
  if state.watcher then
    state.watcher:stop()
    state.watcher:close()
    state.watcher = nil
  end
  state.root = nil
end

local refresh

local function watch(root)
  if state.root == root then
    return
  end
  stop_watching()
  state.root = root
  if not root then
    return
  end

  -- Watch the directory: editors and agents often replace the file on save.
  local watcher = vim.uv.new_fs_event()
  local ok = watcher and watcher:start(root .. "/.ai", {}, vim.schedule_wrap(function()
    state.key = nil
    refresh()
  end))
  if ok then
    state.watcher = watcher
  elseif watcher then
    watcher:close()
  end
end

refresh = function()
  if not is_open() then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if buf == state.buf or vim.bo[buf].buftype ~= "" or name == "" then
    return
  end

  local path, broken = M.scope_path()
  -- Half-typed code can hide the scope. Keep the note on screen until it parses.
  if path == "" and broken then
    return
  end

  local key = name .. "\0" .. path
  if key == state.key then
    return
  end
  state.key = key

  local root = vim.fs.root(name, ".ai")
  watch(root)
  render(root, root and vim.fs.relpath(root, name), path)
end

local function cleanup()
  pcall(vim.api.nvim_del_augroup_by_name, "Brief")
  stop_watching()
  state.win = nil
  state.key = nil
end

local function close()
  if is_open() then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  cleanup()
end

local function normal_windows()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

local function open()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].filetype = "markdown"
    vim.api.nvim_buf_set_name(state.buf, "Brief")
  end

  state.win = vim.api.nvim_open_win(state.buf, false, {
    split = "right",
    win = -1,
    width = WIDTH,
  })
  local wo = vim.wo[state.win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.wrap = true
  wo.linebreak = true
  wo.winfixwidth = true

  local group = vim.api.nvim_create_augroup("Brief", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
    group = group,
    callback = refresh,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(state.win),
    callback = cleanup,
  })
  -- Don't leave the panel behind as the last window after :q.
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      local wins = normal_windows()
      if #wins == 2 and vim.tbl_contains(wins, state.win)
          and vim.api.nvim_get_current_win() ~= state.win then
        close()
      end
    end,
  })

  state.key = nil
  refresh()
end

function M.toggle()
  if is_open() then
    close()
  else
    open()
  end
end

vim.api.nvim_create_user_command("Brief", M.toggle, { desc = "Toggle the brief panel" })
vim.keymap.set("n", "<leader>B", M.toggle, { desc = "Toggle the brief panel" })

return M
