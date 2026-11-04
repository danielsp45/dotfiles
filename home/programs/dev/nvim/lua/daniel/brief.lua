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

-- Returns the file's notes and the most specific scope's notes, either of
-- which can be nil.
function M.lookup(brief, file, path)
  local entry = brief.files[file]
  local file_note = entry and has_text(entry.lines) and entry or nil

  for _, name in ipairs(candidates(path)) do
    local section = find_scope(brief, file, name)
    if section then
      return file_note, section
    end
  end

  return file_note, nil
end

-- Cursor scope ----------------------------------------------------------

local function name_node(node)
  local target = node:field("name")[1]
  if not target then
    local declarator = node:field("declarator")[1]
    while declarator and declarator:field("declarator")[1] do
      declarator = declarator:field("declarator")[1]
    end
    target = declarator
  end
  return target
end

local function is_function(node)
  if node:type() == "function_definition" then
    return true
  end
  local declarator = node:type() == "field_declaration" and node:field("declarator")[1]
  while declarator do
    if declarator:type() == "function_declarator" then
      return true
    end
    declarator = declarator:field("declarator")[1]
  end
  return false
end

-- The identifier itself, as the language server expects: "b" in "A::b".
local function leaf(node)
  while node:field("name")[1] do
    node = node:field("name")[1]
  end
  return node
end

-- Returns the scope under the cursor, such as "BufferPool::evict", whether
-- the syntax tree currently has errors, and, when the innermost scope is a
-- function, the {row, col} of its name.
function M.scope_path()
  local buf = vim.api.nvim_get_current_buf()
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  local types = lang and M.scope_types[lang]
  if not types then
    return "", false, nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return "", false, nil
  end

  local tree = parser:parse()[1]
  local node = vim.treesitter.get_node({ bufnr = buf })
  local parts, pos, innermost = {}, nil, true
  while node do
    if types[node:type()] then
      local target = name_node(node)
      if target then
        table.insert(parts, 1, vim.treesitter.get_node_text(target, buf))
        if innermost and is_function(node) then
          local row, col = leaf(target):start()
          pos = { row, col }
        end
        innermost = false
      end
    end
    node = node:parent()
  end

  return table.concat(parts, "::"), tree ~= nil and tree:root():has_error(), pos
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

local function trimmed(lines)
  local first, last = 1, #lines
  while first <= last and not lines[first]:match("%S") do
    first = first + 1
  end
  while last >= first and not lines[last]:match("%S") do
    last = last - 1
  end
  return vim.list_slice(lines, first, last)
end

local MAX_CALLERS = 15

local function caller_lines(callers)
  if callers.loading then
    return { "## Callers", "", "Loading..." }
  end
  if #callers.items == 0 then
    return { "## Callers", "", "None found" }
  end

  local lines = { "## Callers", "" }
  for i, item in ipairs(callers.items) do
    if i > MAX_CALLERS then
      table.insert(lines, "... and " .. (#callers.items - MAX_CALLERS) .. " more")
      break
    end
    table.insert(lines, ("- %s  %s:%d"):format(item.name, item.file, item.line))
  end
  return lines
end

local function note_lines(root, file, path)
  local brief = root and read_brief(root)
  if not brief then
    return { "No " .. BRIEF .. " in this project" }
  end

  local file_note, scope
  if file then
    file_note, scope = M.lookup(brief, file, path)
  end
  if not file_note and not scope then
    return { "No notes for " .. (path ~= "" and path or file or "this file") }
  end

  local lines = {}
  if file_note then
    table.insert(lines, "# " .. file)
    table.insert(lines, "")
    vim.list_extend(lines, trimmed(file_note.lines))
  end
  if scope then
    if file_note then
      table.insert(lines, "")
    end
    table.insert(lines, "## " .. scope.name)
    if scope.file ~= file then
      table.insert(lines, scope.file)
    end
    table.insert(lines, "")
    vim.list_extend(lines, trimmed(scope.lines))
  end
  return lines
end

local function draw()
  local view = state.view
  local lines = note_lines(view.root, view.file, view.path)
  if state.callers and state.callers.key == state.key then
    table.insert(lines, "")
    vim.list_extend(lines, caller_lines(state.callers))
  end
  set_lines(lines)
end

-- Callers ---------------------------------------------------------------

local function display_path(fname)
  local rel = state.root and vim.fs.relpath(state.root, fname)
  return rel or vim.fn.fnamemodify(fname, ":~:.")
end

local function finish_callers(key, calls)
  if state.key ~= key or not is_open() then
    return
  end

  local items = {}
  for _, call in ipairs(calls) do
    local from = call.from
    local range = (call.fromRanges and call.fromRanges[1]) or from.selectionRange
    table.insert(items, {
      name = from.name,
      file = display_path(vim.uri_to_fname(from.uri)),
      line = range.start.line + 1,
    })
  end
  table.sort(items, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    return a.line < b.line
  end)

  state.callers = { key = key, items = items }
  draw()
end

-- Asks the language server who calls the function at pos. Results that
-- arrive after the cursor has moved to another scope are dropped.
local function fetch_callers(buf, pos, key)
  local client = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/prepareCallHierarchy" })[1]
  if not client then
    return
  end

  local line = vim.api.nvim_buf_get_lines(buf, pos[1], pos[1] + 1, false)[1] or ""
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    position = {
      line = pos[1],
      character = vim.str_utfindex(line, client.offset_encoding, pos[2], false),
    },
  }

  state.callers = { key = key, loading = true }
  client:request("textDocument/prepareCallHierarchy", params, vim.schedule_wrap(function(err, items)
    if state.key ~= key then
      return
    end
    if err or not items or not items[1] then
      return finish_callers(key, {})
    end
    client:request("callHierarchy/incomingCalls", { item = items[1] }, vim.schedule_wrap(function(err2, calls)
      finish_callers(key, (not err2 and calls) or {})
    end), buf)
  end), buf)
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

  local path, broken, pos = M.scope_path()
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
  state.view = { root = root, file = root and vim.fs.relpath(root, name), path = path }
  state.callers = nil
  if pos then
    fetch_callers(buf, pos, key)
  end
  draw()
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
  -- The language server often attaches after the panel first draws.
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = vim.schedule_wrap(function()
      state.key = nil
      refresh()
    end),
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
