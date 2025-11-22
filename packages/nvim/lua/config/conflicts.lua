local M                     = {}
local api                   = vim.api
local utils                 = require 'config.utils'
local NO_FOCUS_FLAG         = "conflicts_no_focus"
local CONFLICT_MARKER_COUNT = 3

local _conflicts            = {}
local _is_locked            = false
local _cursor_pos           = 1

local function join_tables(t1, t2)
  local t = {}
  for _, v in ipairs(t1) do table.insert(t, v) end
  for _, v in ipairs(t2) do table.insert(t, v) end
  return t
end

local function highlight(buf, ns, from, to)
  for i = 1, to do
    api.nvim_buf_set_extmark(buf, ns, from + i - 2, 0, {
      line_hl_group = 'Conflict',
      hl_mode = 'blend',
      hl_eol = true
    })
  end
end

function M.apply_highlights(left_buf, right_buf, conflicts)
  api.nvim_buf_clear_namespace(left_buf, -1, 0, -1)
  api.nvim_buf_clear_namespace(right_buf, -1, 0, -1)

  for conflict_idx, conflict in ipairs(conflicts) do
    local ours = conflict.ours.len
    local theirs = conflict.theirs.len
    local ns = api.nvim_create_namespace('conflict_mark:' .. conflict_idx)
    local l_buf_padding = math.max(theirs - ours, 0)
    local r_buf_padding = math.max(ours - theirs, 0)

    highlight(left_buf, ns, conflict.from, ours + l_buf_padding)
    highlight(right_buf, ns, conflict.from, theirs + r_buf_padding)
  end
end

function M.get_file_content(lines, conflicts)
  local ours = {}
  local theirs = {}
  local conflict_idx = 1
  local line_idx = 1

  while line_idx <= #lines do
    local conflict = conflicts[conflict_idx]
    if conflict and conflict.original_from == line_idx then
      line_idx = line_idx + 1
      for _ = 1, conflict.ours.len do
        table.insert(ours, lines[line_idx])
        line_idx = line_idx + 1
      end
      -- Space padding to make sure both sides have the same length.
      if conflict.ours.len < conflict.theirs.len then
        for _ = 1, conflict.theirs.len - conflict.ours.len do
          table.insert(ours, "")
        end
      end
      line_idx = line_idx + 1
      for _ = 1, conflict.theirs.len do
        table.insert(theirs, lines[line_idx])
        line_idx = line_idx + 1
      end
      -- Space padding to make sure both sides have the same length.
      if conflict.theirs.len < conflict.ours.len then
        for _ = 1, conflict.ours.len - conflict.theirs.len do
          table.insert(theirs, "")
        end
      end
      conflict_idx = conflict_idx + 1
    else
      -- Regular lines, add to both.
      table.insert(ours, lines[line_idx])
      table.insert(theirs, lines[line_idx])
    end
    line_idx = line_idx + 1
  end

  return { ours = ours, theirs = theirs }
end

function M.file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function M.parse(lines)
  local conflicts = {}
  local conflict = {}
  local line_number = 0
  local total_removed_lines = 0

  for _, line in ipairs(lines) do
    line_number = line_number + 1
    if line:match("^<<<<<<<") then
      conflict = { from = line_number - total_removed_lines, original_from = line_number }
    elseif line:match("^=======") then
      conflict.ours = { len = line_number - conflict.from - 1 - total_removed_lines }
    elseif line:match("^>>>>>>>") then
      conflict.theirs = { len = line_number - conflict.from - conflict.ours.len - 2 - total_removed_lines }
      total_removed_lines = total_removed_lines + 3 + math.min(conflict.ours.len, conflict.theirs.len)
      conflict.to = line_number - total_removed_lines -- Is this needed?
      conflict.original_to = line_number
      table.insert(conflicts, conflict)
      conflict = nil
    end
  end

  return conflicts
end

local function refresh_buffers_content(original_buf, buf1, buf2)
  local lines = api.nvim_buf_get_lines(original_buf, 0, -1, false)
  _conflicts = M.parse(lines)
  local file_content = M.get_file_content(lines, _conflicts)

  api.nvim_buf_set_lines(buf1, 0, -1, false, file_content.ours)
  api.nvim_buf_set_lines(buf2, 0, -1, false, file_content.theirs)

  M.apply_highlights(buf1, buf2, _conflicts)
end

local function undo(original_buf, buf1, buf2)
  api.nvim_buf_call(original_buf, function()
    _is_locked = true
    api.nvim_cmd({ cmd = "undo", args = {} }, {})
    -- PERF: Relatively expensive on every undo but good enough for now.
    refresh_buffers_content(original_buf, buf1, buf2)
    _is_locked = false
  end)
end

local function redo(original_buf, ours_buf, theirs_buf)
  api.nvim_buf_call(original_buf, function()
    _is_locked = true
    api.nvim_cmd({ cmd = "redo", args = {} }, {})
    -- PERF: Relatively expensive on every redo but good enough for now.
    refresh_buffers_content(original_buf, ours_buf, theirs_buf)
    _is_locked = false
  end)
end

local function jump_to_next_conflict()
  if #_conflicts == 0 then return end
  vim.schedule(function()
    local curr_line = api.nvim_win_get_cursor(0)[1]

    for _, conflict in ipairs(_conflicts) do
      if curr_line < conflict.from then
        api.nvim_win_set_cursor(0, { conflict.from, 0 })
        return
      end
    end

    -- If we are at the end of the file with no more conflicts, jump to the first conflict.
    api.nvim_win_set_cursor(0, { _conflicts[1].from, 0 })
  end)
end

local function jump_to_prev_conflict()
  if #_conflicts == 0 then return end
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for i = #_conflicts, 1, -1 do
    local conflict = _conflicts[i]
    if curr_line > conflict.from then
      api.nvim_win_set_cursor(0, { conflict.from, 0 })
      return
    end
  end

  -- If we are at the start of the file with no more conflicts, jump to the last conflict.
  api.nvim_win_set_cursor(0, { _conflicts[#_conflicts].from, 0 })
end

local function on_accept_both(original_buf, ours_buf, theirs_buf)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(_conflicts) do
    if curr_line >= conflict.from and curr_line <= conflict.to then
      local start = conflict.from - 1
      local ours_buf_lines = api.nvim_buf_get_lines(ours_buf, start, start + conflict.ours.len, false)
      local theirs_buf_lines = api.nvim_buf_get_lines(theirs_buf, start, start + conflict.theirs.len, false)
      local all_lines = join_tables(ours_buf_lines, theirs_buf_lines)

      _is_locked = true
      api.nvim_buf_set_lines(original_buf, conflict.original_from - 1, conflict.original_to, false, all_lines)
      -- PERF: Relatively expensive on every accept but good enough for now.
      refresh_buffers_content(original_buf, ours_buf, theirs_buf)
      _is_locked = false
    end
  end
end

local function on_accept(original_buf_nr, ours_buf, theirs_buf, side)
  local curr_line = api.nvim_win_get_cursor(0)[1]

  for _, conflict in ipairs(_conflicts) do
    if curr_line >= conflict.from and curr_line <= conflict.to then
      local curr_buf = api.nvim_get_current_buf()
      local start = conflict.from - 1
      local len = conflict[side].len
      local lines = api.nvim_buf_get_lines(curr_buf, start, start + len, false)
      _is_locked = true
      api.nvim_buf_set_lines(original_buf_nr, conflict.original_from - 1, conflict.original_to, false, lines)
      -- PERF: Relatively expensive on every accept but good enough for now.
      refresh_buffers_content(original_buf_nr, ours_buf, theirs_buf)
      _is_locked = false
    end
  end
end

local function get_offset_for_original_buf(to, conflict_side)
  local offset = 0
  local from = _cursor_pos
  to = to + 1 -- conflicts use 1-based indexing
  for _, conflict in ipairs(_conflicts) do
    if to <= conflict.from then break end

    if from > conflict.to then -- Outside the conflict.
      if conflict_side == 'ours' then
        offset = offset + conflict.theirs.len
      else
        offset = offset + conflict.ours.len
      end
      offset = offset + CONFLICT_MARKER_COUNT
    else -- Inside the conflict.
      if conflict_side == 'ours' then
        offset = offset + CONFLICT_MARKER_COUNT - 2
      else
        offset = offset + conflict.ours.len + CONFLICT_MARKER_COUNT - 1
      end
    end
  end
  return offset
end

local function is_change_in_conflict()
  for _, conflict in ipairs(_conflicts) do
    if _cursor_pos >= conflict.from and _cursor_pos <= conflict.to then return true end
  end
  return false
end

local function is_range_spanning_conflicts(first_line, last_line)
  local start_line = first_line + 1
  local end_line = last_line
  local start_conflict, end_conflict

  for _, conflict in ipairs(_conflicts) do
    if start_line >= conflict.from and start_line <= conflict.to then
      start_conflict = conflict
    end
    if end_line >= conflict.from and end_line <= conflict.to then
      end_conflict = conflict
    end
  end

  -- Range spans conflicts if start is inside a conflict and end is outside or in a different conflict
  return start_conflict and (not end_conflict or start_conflict ~= end_conflict)
end

-- Maps split view (when deleted range goes through marker boundary) line numbers to original buffer line numbers accounting for conflict markers.
-- Returns indices of original buffer lines corresponding to the deleted split view range.
local function map_split_to_original_lines(first_line, last_line, side)
  local split_to_original = {}
  local split_idx = 1
  local orig_idx = 1

  -- Build mapping for each region
  for _, conflict in ipairs(_conflicts) do
    -- Regular lines before conflict map 1:1
    while split_idx < conflict.from do
      split_to_original[split_idx] = orig_idx
      split_idx = split_idx + 1
      orig_idx = orig_idx + 1
    end

    -- Conflict lines map to positions within conflict markers
    local max_len = math.max(conflict.ours.len, conflict.theirs.len)
    for i = 0, max_len - 1 do
      if side == 'ours' and i < conflict.ours.len then
        split_to_original[conflict.from + i] = conflict.original_from + 1 + i
      elseif side == 'theirs' and i < conflict.theirs.len then
        split_to_original[conflict.from + i] = conflict.original_from + conflict.ours.len + 2 + i
      end
    end

    split_idx = conflict.from + max_len
    orig_idx = conflict.original_to + 1
  end

  -- Map remaining lines after last conflict (only up to what we need)
  local max_needed = last_line
  for i = 0, max_needed - split_idx + 1 do
    split_to_original[split_idx + i] = orig_idx + i
  end

  -- Convert deleted split range to original buffer indices
  local lines_to_delete = {}
  for i = first_line, last_line - 1 do
    local orig = split_to_original[i + 1]
    if orig then
      table.insert(lines_to_delete, orig - 1)
    end
  end

  return lines_to_delete
end

local function on_lines_change(buf, other_buf, original_buf, side)
  return function(_, _, _, first_line, last_line, new_end)
    if _is_locked then return end

    vim.schedule(function()
      local lines_added = new_end - first_line
      local lines_removed = last_line - first_line
      local in_conflict = is_change_in_conflict()
      local spans_conflicts = is_range_spanning_conflicts(first_line, last_line)
      local original_file_offset = get_offset_for_original_buf(last_line, side)
      local added_lines = api.nvim_buf_get_lines(buf, first_line, new_end, false)
      _is_locked = true

      if not in_conflict then
        if lines_added < lines_removed then
          api.nvim_buf_set_lines(other_buf, first_line, last_line, false, {})
        else
          api.nvim_buf_set_lines(other_buf, first_line, last_line, false, added_lines)
        end
      end

      if spans_conflicts and lines_added < lines_removed then
        -- When deleting across conflict boundaries, map split view lines to original buffer positions
        local lines_to_delete = map_split_to_original_lines(first_line, last_line, side)
        table.sort(lines_to_delete)

        -- Group consecutive line indices into ranges for efficient deletion
        local ranges = {}
        local i = 1
        while i <= #lines_to_delete do
          local start = lines_to_delete[i]
          local finish = start
          while i < #lines_to_delete and lines_to_delete[i + 1] == finish + 1 do
            i = i + 1
            finish = lines_to_delete[i]
          end
          table.insert(ranges, { start, finish })
          i = i + 1
        end

        -- Delete ranges in reverse to avoid index shifting
        for idx = #ranges, 1, -1 do
          api.nvim_buf_set_lines(original_buf, ranges[idx][1], ranges[idx][2] + 1, false, {})
        end

        local ours_buf = side == 'ours' and buf or other_buf
        local theirs_buf = side == 'theirs' and buf or other_buf
        refresh_buffers_content(original_buf, ours_buf, theirs_buf)
      else
        if lines_added > lines_removed then
          local line = first_line + original_file_offset
          api.nvim_buf_set_lines(original_buf, line, line, false, added_lines)
        elseif lines_added < lines_removed then
          api.nvim_buf_set_lines(original_buf, first_line + original_file_offset, last_line + original_file_offset, false,
            {})
        elseif lines_added == lines_removed then
          local line = first_line + original_file_offset
          api.nvim_buf_set_lines(original_buf, line, line + 1, false, added_lines)
        end

        if lines_added ~= lines_removed then
          local ours_buf = side == 'ours' and buf or other_buf
          local theirs_buf = side == 'theirs' and buf or other_buf
          refresh_buffers_content(original_buf, ours_buf, theirs_buf)
        end
      end

      _is_locked = false
    end)
  end
end

local function main()
  local buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  _conflicts = M.parse(lines)
  if #_conflicts == 0 then return end

  local filetype = vim.bo.filetype
  local buf1 = api.nvim_create_buf(false, true)
  local buf2 = api.nvim_create_buf(false, true)
  local winnr = api.nvim_get_current_win()
  local file_content = M.get_file_content(lines, _conflicts)

  api.nvim_buf_set_lines(buf1, 0, -1, false, file_content.ours)
  api.nvim_buf_set_lines(buf2, 0, -1, false, file_content.theirs)
  api.nvim_buf_set_option(buf1, 'filetype', filetype)
  api.nvim_buf_set_option(buf2, 'filetype', filetype)
  api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, true)

  local win_config1 = { relative = 'editor', width = vim.o.columns / 2, height = vim.o.lines, col = 0, row = 0 }
  local win_config2 = vim.tbl_extend("force", win_config1, { col = vim.o.columns / 2 })
  local win1 = api.nvim_open_win(buf1, true, win_config1)
  local win2 = api.nvim_open_win(buf2, true, win_config2)
  api.nvim_set_current_win(win1)

  -- Sync scroll
  api.nvim_win_set_option(win1, 'scrollbind', true)
  api.nvim_win_set_option(win2, 'scrollbind', true)
  api.nvim_win_set_option(win1, 'cursorbind', true)
  api.nvim_win_set_option(win2, 'cursorbind', true)

  M.apply_highlights(buf1, buf2, _conflicts)

  local buf_enter_autocmd_id = api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local ok, skip = pcall(api.nvim_win_get_var, 0, NO_FOCUS_FLAG)
      -- Skip this window and move to the next.
      if ok and skip then vim.cmd("wincmd w") end
    end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed1', { clear = true }),
    buffer = buf1,
    callback = function()
      api.nvim_win_close(win2, true)
      api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, false)
      api.nvim_del_autocmd(buf_enter_autocmd_id)
      api.nvim_buf_call(buf, function() api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {}) end)
    end,
  })
  api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = vim.api.nvim_create_augroup('buf_closed2', { clear = true }),
    buffer = buf2,
    callback = function()
      api.nvim_win_close(win1, true)
      api.nvim_win_set_var(winnr, NO_FOCUS_FLAG, false)
      api.nvim_del_autocmd(buf_enter_autocmd_id)
      api.nvim_buf_call(buf, function() api.nvim_cmd({ cmd = "write", args = {}, mods = { silent = true } }, {}) end)
    end,
  })

  api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = vim.api.nvim_create_augroup('conflict_resolve_cursor_move_1', { clear = true }),
    buffer = buf1,
    callback = function() _cursor_pos = api.nvim_win_get_cursor(0)[1] end,
  })
  api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = vim.api.nvim_create_augroup('conflict_resolve_cursor_move_2', { clear = true }),
    buffer = buf2,
    callback = function() _cursor_pos = api.nvim_win_get_cursor(0)[1] end,
  })

  api.nvim_buf_set_keymap(buf1, 'n', 'u', '', { callback = function() undo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', 'u', '', { callback = function() undo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '<C-r>', '', { callback = function() redo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', '<C-r>', '', { callback = function() redo(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '[c', '', { callback = jump_to_next_conflict })
  api.nvim_buf_set_keymap(buf2, 'n', '[c', '', { callback = jump_to_next_conflict })
  api.nvim_buf_set_keymap(buf1, 'n', ']c', '', { callback = jump_to_prev_conflict })
  api.nvim_buf_set_keymap(buf2, 'n', ']c', '', { callback = jump_to_prev_conflict })
  api.nvim_buf_set_keymap(buf1, 'n', '<leader>b', '', { callback = function() on_accept_both(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf2, 'n', '<leader>b', '', { callback = function() on_accept_both(buf, buf1, buf2) end })
  api.nvim_buf_set_keymap(buf1, 'n', '<leader>a', '', { callback = function() on_accept(buf, buf1, buf2, "ours") end })
  api.nvim_buf_set_keymap(buf2, 'n', '<leader>a', '', { callback = function() on_accept(buf, buf1, buf2, "theirs") end })

  api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  api.nvim_buf_attach(buf1, false, { on_lines = on_lines_change(buf1, buf2, buf, 'ours') })
  api.nvim_buf_attach(buf2, false, { on_lines = on_lines_change(buf2, buf1, buf, 'theirs') })
end

api.nvim_create_autocmd({ 'BufReadPost' }, {
  group = vim.api.nvim_create_augroup('conflict_resolve', { clear = true }),
  callback = utils.async(function()
    local nvim_env = os.getenv('NVIM_ENV')
    if nvim_env == 'test' then return main() end

    local git_status = utils.spawn("git", { 'diff', '--name-only', '--diff-filter=U' })
    if git_status == "" then return end

    utils.vim_loop(function()
      local bufname = api.nvim_buf_get_name(0)
      for file in git_status:gmatch("[^\r\n]+") do
        if bufname:match(file .. '$') then return main() end
      end
    end)
  end)
})

return M
