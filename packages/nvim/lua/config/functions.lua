local M = {}
local api = vim.api
local popup = require("plenary.popup")
local illuminate = require("illuminate")
local previewers = require("telescope.previewers")
local previewer_utils = require("telescope.previewers.utils")
local pickers = require("telescope.pickers")
local builtin = require("telescope.builtin")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local telescope_utils = require("telescope.utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local statusline = require("config.statusline")
local utils = require("config.utils")
local colors = require("config.colors")

-- Delta settings matching the nvim theme. Syntax colors come from the terminal palette set in appearance.lua.
local delta_config = {
	["core.pager"] = "delta",
	["delta.side-by-side"] = "false",
	["delta.syntax-theme"] = "base16",
	["delta.plus-style"] = "syntax " .. colors.diff_add_bg,
	["delta.plus-emph-style"] = "syntax " .. colors.dark_primary,
	["delta.minus-style"] = "syntax " .. colors.diff_delete_bg,
	["delta.minus-emph-style"] = "syntax " .. colors.diff_delete_emph_bg,
	["delta.file-style"] = colors.primary,
	["delta.file-decoration-style"] = colors.primary .. " ul",
	["delta.hunk-header-style"] = "file line-number syntax",
	["delta.hunk-header-file-style"] = colors.light_primary,
	["delta.hunk-header-line-number-style"] = colors.gray,
	["delta.hunk-header-decoration-style"] = colors.gray .. " box",
}

-- Build a `git <args>` command piped through themed delta.
local function git_delta(args)
	local cmd = { "git" }
	for key, value in pairs(delta_config) do
		vim.list_extend(cmd, { "-c", key .. "=" .. value })
	end
	return vim.list_extend(cmd, args)
end

local function git_show(object)
	return vim.fn.systemlist({ "git", "show", object })
end

-- Overlay the changes against `base` on top of `bufnr`, `on_ready` runs once the hunks are computed.
local function show_changes(bufnr, base, on_ready)
	local minidiff = require("mini.diff")
	api.nvim_create_autocmd("User", {
		pattern = "MiniDiffUpdated",
		callback = function(args)
			if not api.nvim_buf_is_valid(bufnr) then
				return true
			end
			if args.buf == bufnr then
				on_ready()
				return true
			end
		end,
	})
	minidiff.set_ref_text(bufnr, base)
	minidiff.toggle_overlay(bufnr)
end

-- Jump to the next/previous hunk in the preview, centered like <C-h>/<S-h> in regular buffers.
local function goto_preview_hunk(prompt_bufnr, direction)
	local minidiff = require("mini.diff")
	local winid = action_state.get_current_picker(prompt_bufnr).preview_win
	if not winid or not api.nvim_win_is_valid(winid) then
		return
	end
	local bufnr = api.nvim_win_get_buf(winid)
	-- Hunks are computed asynchronously, so they may not be ready right after the preview opens.
	local data = minidiff.get_buf_data(bufnr)
	if not data or #data.hunks == 0 then
		return
	end

	api.nvim_win_call(winid, function()
		-- The preview opens at the top, so the first jump should land on a hunk at line 1 too.
		if direction == "next" and not vim.b.hunk_nav_started then
			direction = "first"
		end
		vim.b.hunk_nav_started = true
		minidiff.goto_hunk(direction, { wrap = vim.o.wrapscan })

		local first = data.hunks[1]
		if vim.fn.line(".") == 1 and first.buf_start <= 1 then
			-- Old lines above line 1 are only visible as filler.
			vim.fn.winrestview({ topline = 1, topfill = first.ref_count })
		else
			vim.cmd("normal! zz")
		end
	end)
end

local delta_bcommits = previewers.new_termopen_previewer({
	get_command = function(entry)
		return git_delta({ "diff", entry.value .. "^!", "--", entry.current_file })
	end,
})

local delta = previewers.new_termopen_previewer({
	get_command = function(entry)
		return git_delta({ "diff", entry.path })
	end,
})

function SubmitRenamePopup(win_id)
	local bufnr = vim.api.nvim_win_get_buf(0)
	local val = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	ClosePopup(win_id)

	local client = utils.get_attached_lsp_client(function(c)
		return c.server_capabilities.renameProvider
	end)
	if not client then
		return
	end

	local method = "textDocument/rename"
	local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
	params.newName = val[1]

	local res = client.request_sync(method, params, 1000)

	if res.err then
		print("Rename failed: ", res.err)
		return
	end

	vim.lsp.handlers[method](nil, res.result, {
		method = method,
		client_id = client.id,
		bufnr = bufnr,
		params = params,
	})
	vim.cmd("wa")
end

function ClosePopup(win_id)
	vim.api.nvim_win_close(win_id, true)
	vim.api.nvim_input("<Esc>")
	illuminate.toggle()
end

function OpenPopup(title, val, submit)
	local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
	local ui = vim.api.nvim_list_uis()[1]
	local height = 1
	local width = ui.width / 2

	local win_id = popup.create({}, {
		title = title,
		line = math.floor(((vim.o.lines - height) / 2) - 1),
		col = math.floor((vim.o.columns - width) / 2),
		minwidth = width,
		minheight = height,
		borderchars = borderchars,
		-- Not implemented yet by plenary.
		callback = nil,
	})
	illuminate.toggle()

	local bufnr = vim.api.nvim_win_get_buf(win_id)
	local keymap_opts = { silent = true, nowait = true, noremap = true }
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { val })
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
	vim.api.nvim_buf_set_keymap(bufnr, "i", "<CR>", "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>lua ClosePopup(" .. win_id .. ")<CR>", keymap_opts)
end

M.my_git_status = function(opts)
	local last_commit = vim.fn.system("git log -1 --pretty=%B"):gsub("\n", ""):gsub(" #.*", "")

	local function get_git_files()
		local git_status = vim.fn.system("git status -s")
		local files = {}
		local staged_files = {}

		for line in git_status:gmatch("[^\r\n]+") do
			local status = line:sub(1, 2)
			local filename = line:sub(4)
			local staged_status = status:sub(1, 1)
			local unstaged_status = status:sub(2, 2)

			local abs_path = vim.fn.fnamemodify(filename, ":p")
			local is_conflict = staged_status == "U" or unstaged_status == "U"

			if is_conflict then
				table.insert(files, {
					abs_path = abs_path,
					filename = filename,
					is_staged = false,
					staged_status = "U",
					unstaged_status = "U",
					status = "UU",
				})
			else
				local has_staged = staged_status ~= " " and staged_status ~= "?"
				local has_unstaged = unstaged_status ~= " "

				if has_staged then
					table.insert(files, {
						abs_path = abs_path,
						filename = filename,
						is_staged = true,
						staged_status = staged_status,
						unstaged_status = " ",
						status = staged_status .. " ",
					})
					staged_files[abs_path] = true
				end

				if has_unstaged then
					table.insert(files, {
						abs_path = abs_path,
						filename = filename,
						is_staged = false,
						staged_status = " ",
						unstaged_status = unstaged_status,
						status = " " .. unstaged_status,
					})
				end
			end
		end

		return files, staged_files
	end

	local displayer = entry_display.create({
		separator = "",
		items = {
			{ width = 2 },
			{ width = 2 },
			{ remaining = true },
			{ width = 100 },
		},
	})

	local function make_display(entry)
		local parent = vim.fs.dirname(entry.filename)
		local basename = vim.fs.basename(entry.filename)
		parent = vim.fn.fnamemodify(parent, ":~:.")
		local staged_icon = entry.value.is_staged and "" or " "

		local status = entry.value.is_staged and entry.value.staged_status or entry.value.unstaged_status
		local status_icon = "  "
		local status_hl = "TelescopeResultsComment"
		if status == "U" then
			status_icon = ""
			status_hl = "DiagnosticError"
		elseif status == "M" then
			status_icon = ""
			status_hl = "GitSignsChange"
		elseif status == "A" or status == "?" then
			status_icon = ""
			status_hl = "GitSignsAdd"
		elseif status == "D" then
			status_icon = ""
			status_hl = "GitSignsDelete"
		end

		return displayer({
			{
				staged_icon,
				entry.value.is_staged and "GitSignsAdd" or "TelescopeResultsComment",
			},
			{ status_icon, status_hl },
			{ " " .. basename .. " ", "TelescopeResultsIdentifier" },
			{ parent, "TelescopeResultsComment" },
		})
	end

	local function create_finder()
		local files, _ = get_git_files()
		if #files == 0 then
			return nil
		end

		table.sort(files, function(a, b)
			if (a.status == "UU") ~= (b.status == "UU") then
				return a.status == "UU"
			end
			return a.abs_path < b.abs_path
		end)

		return finders.new_table({
			results = files,
			entry_maker = function(entry)
				return {
					value = entry,
					display = make_display,
					filename = entry.abs_path,
					ordinal = entry.abs_path,
				}
			end,
		})
	end

	-- Results window view to restore once a refresh completes.
	local saved_view

	local function refresh(prompt_bufnr)
		local new_finder = create_finder()
		if not new_finder then
			actions.close(prompt_bufnr)
			illuminate.toggle()
			return false
		end
		local current_picker = action_state.get_current_picker(prompt_bufnr)
		saved_view = vim.api.nvim_win_call(current_picker.results_win, vim.fn.winsaveview)
		current_picker:refresh(new_finder, { reset_prompt = false })
		return true
	end

	-- TODO: Maybe displaying initial empty is fine?
	local finder = create_finder()
	if not finder then
		return
	end

	local diff_previewer = previewers.new_termopen_previewer({
		get_command = function(entry)
			if entry.value.is_staged then
				if entry.value.staged_status == "D" then
					return { "echo", "The file was deleted." }
				else
					return git_delta({ "diff", "--staged", entry.value.filename })
				end
			else
				if entry.value.unstaged_status == "D" then
					return { "echo", "The file was deleted" }
				else
					return git_delta({ "diff", entry.value.filename })
				end
			end
		end,
	})

	local file_previewer = previewers.new_buffer_previewer({
		define_preview = function(self, entry, status)
			local value = entry.value
			local file_status = value.is_staged and value.staged_status or value.unstaged_status
			if not value.is_staged and file_status ~= "M" then
				conf.buffer_previewer_maker(value.abs_path, self.state.bufnr, {
					bufname = self.state.bufname,
					winid = self.state.winid,
				})
				return
			end

			-- Show the staged content for staged rows, the working tree version may have changed since.
			local lines = value.is_staged and git_show(":./" .. value.filename) or vim.fn.readfile(value.abs_path)
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			previewer_utils.highlighter(self.state.bufnr, previewer_utils.filetype_detect(value.filename))

			if file_status == "M" then
				local base = git_show((value.is_staged and "HEAD:./" or ":./") .. value.filename)
				local bufnr = self.state.bufnr
				show_changes(bufnr, base, function()
					-- Start on the first change, unless another file got previewed in the meantime.
					if api.nvim_win_is_valid(status.preview_win) and api.nvim_win_get_buf(status.preview_win) == bufnr then
						goto_preview_hunk(status.prompt_bufnr, "next")
					end
				end)
			end
		end,
	})

	local preview_timer

	-- Show new, modified and conflicted files as nvim buffers (changes marked on top), delta covers the rest.
	local previewer = previewers.Previewer:new({
		preview_fn = function(self, entry, status)
			local function render()
				local file_status = entry.value.is_staged and entry.value.staged_status or entry.value.unstaged_status
				local use_buffer = file_status == "A" or file_status == "?" or file_status == "M" or file_status == "U"
				self.state.current = use_buffer and file_previewer or diff_previewer
				self.state.current:preview(entry, status)
			end

			-- Render the first preview right away, then wait for the selection to settle.
			if not self.state.current then
				render()
				return
			end
			if preview_timer then
				utils.clearTimeout(preview_timer)
			end
			preview_timer = utils.setTimeout(200, render)
		end,
		scroll_fn = function(self, direction)
			if self.state then
				self.state.current:scroll_fn(direction)
			end
		end,
		teardown = function()
			if preview_timer then
				utils.clearTimeout(preview_timer)
				preview_timer = nil
			end
			file_previewer:teardown()
			diff_previewer:teardown()
		end,
	})

	local picker = pickers.new(opts or {}, {
		prompt_title = "Git Status",
		prompt_prefix = "",
		default_text = last_commit,
		get_status_text = function()
			return ""
		end,
		initial_mode = "normal",
		layout_config = { width = { padding = 0 }, height = { padding = 0 } },
		-- Keep the cursor on the same row after staging/unstaging refreshes the list.
		selection_strategy = "row",
		finder = finder,
		previewer = previewer,
		attach_mappings = function(prompt_bufnr, map)
			map({ "n" }, "<tab>", function()
				local entry = action_state.get_selected_entry(prompt_bufnr)
				if not entry then
					return
				end

				if entry.value.is_staged then
					vim.fn.system("git reset HEAD " .. vim.fn.shellescape(entry.value.filename))
				else
					vim.fn.system("git add " .. vim.fn.shellescape(entry.value.filename))
				end

				-- `selection_strategy = "row"` keeps the cursor in place across the refresh.
				refresh(prompt_bufnr)
			end)

			map({ "n" }, "<C-h>", function()
				goto_preview_hunk(prompt_bufnr, "next")
			end)

			map({ "n" }, "<S-h>", function()
				goto_preview_hunk(prompt_bufnr, "prev")
			end)

			map({ "n" }, "<M-u>", function()
				local entry = action_state.get_selected_entry(prompt_bufnr)
				if not entry then
					return
				end

				local is_untracked = (entry.value.is_staged and entry.value.staged_status == "?")
					or (not entry.value.is_staged and entry.value.unstaged_status == "?")

				if is_untracked then
					vim.fn.system("rm " .. vim.fn.shellescape(entry.value.filename))
				else
					vim.fn.system("git restore --worktree --staged " .. vim.fn.shellescape(entry.value.filename))
				end

				refresh(prompt_bufnr)
			end)

			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				illuminate.toggle()
				vim.cmd("edit " .. action_state.get_selected_entry().filename)
			end)

			map(
				{ "i", "n" },
				"<M-CR>",
				utils.async(function()
					local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
					local _, staged_files = get_git_files()

					if vim.tbl_count(staged_files) == 0 then
						vim.notify("No staged files to commit", vim.log.levels.WARN)
						return
					end

					utils.spawn("git", { "commit", "-m", prompt })
					utils.vim_loop(function()
						actions.close(prompt_bufnr)
						illuminate.toggle()
						statusline.refresh()
					end)
				end)
			)

			return true
		end,
	})

	-- Telescope jumps the results window to the top after every refresh, restore the previous scroll instead.
	picker:register_completion_callback(function(p)
		if not saved_view or not vim.api.nvim_win_is_valid(p.results_win) then
			return
		end
		local topline = saved_view.topline
		saved_view = nil
		vim.api.nvim_win_call(p.results_win, function()
			vim.fn.winrestview({ topline = topline, lnum = p:get_selection_row() + 1, col = 0 })
		end)
	end)

	-- The prompt is the commit message, not a filter, so typing shouldn't re-run the finder and redraw
	-- the results/preview. `refresh` still triggers it directly.
	picker:_toggle_finder_attach()

	illuminate.toggle()
	picker:find()

	-- Move prompt cursor to beginning of line.
	vim.schedule(function()
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end)
end

M.my_git_commits = function(opts)
	opts = opts or {}
	opts.previewer = {
		delta,
		previewers.git_commit_message.new(opts),
		previewers.git_commit_diff_as_was.new(opts),
	}

	builtin.git_commits(opts)
end

M.my_git_bcommits = function(opts)
	opts = opts or {}
	opts.previewer = {
		delta_bcommits,
		previewers.git_commit_message.new(opts),
		previewers.git_commit_diff_as_was.new(opts),
	}

	builtin.git_bcommits(opts)
end

function M.rename()
	local win = api.nvim_get_current_win()
	local buf = api.nvim_win_get_buf(win)
	local cursor = api.nvim_win_get_cursor(win)
	local line = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
	local cursor_pos = cursor[2] + 1
	local current_char = line:sub(cursor_pos, cursor_pos)

	if not current_char:match("[%w_-]") then
		return
	end

	local prefix = ""
	local suffix = ""

	current_char = line:sub(cursor_pos, cursor_pos)
	while current_char:match("[%w_-]") do
		prefix = current_char .. prefix
		cursor_pos = cursor_pos - 1
		current_char = line:sub(cursor_pos, cursor_pos)
	end

	cursor_pos = cursor[2] + 1 + 1
	current_char = line:sub(cursor_pos, cursor_pos)
	while current_char:match("[%w_-]") do
		suffix = suffix .. current_char
		cursor_pos = cursor_pos + 1
		current_char = line:sub(cursor_pos, cursor_pos)
	end

	local var_name = prefix .. suffix
	OpenPopup("Refactor", var_name, "SubmitRenamePopup")
end

function M.go_to_usages()
	local client = vim.lsp.get_clients({ bufnr = 0 })[1]
	local params = vim.lsp.util.make_position_params(0, client and client.offset_encoding or "utf-16")
	params.context = { includeDeclaration = false }

	vim.lsp.buf_request_all(0, "textDocument/references", params, function(result)
		if not result then
			return
		end

		-- LSP returns a weird hash table so extract the first and only value.
		for _, v in pairs(result) do
			result = v.result
		end

		-- Filter out all references that are part of import statements.
		-- TODO: Open files in parallel, think about using ast parsing to determine if it's an import.
		local filtered_refs = {}
		local prev_line = ""

		if not result then
			vim.notify("No references found")
			return
		end
		for _, ref in ipairs(result) do
			local file_path = ref.uri
			local lines = vim.fn.readfile(vim.uri_to_fname(file_path))
			local line = lines[ref.range.start.line + 1]

			if prev_line ~= line and not line:match("^import") and not line:match("^[ \t]*>*</%w+>") then
				table.insert(filtered_refs, ref)
			end

			prev_line = line
		end

		local total = 0
		for _, _ in ipairs(filtered_refs) do
			total = total + 1
		end

		if total == 0 then
			return
		end
		if total == 1 then
			for _, ref in ipairs(filtered_refs) do
				local start = ref.range.start
				vim.api.nvim_command("edit " .. ref.uri:gsub("^file://", ""))
				vim.api.nvim_win_set_cursor(0, { start.line + 1, start.character })
				return
			end
		end

		local files = {}
		local items = {}
		for _, ref in ipairs(filtered_refs) do
			local item = {}
			local filename = vim.uri_to_fname(ref.uri)
			if not files[filename] then
				files[filename] = 1
			end

			item.basename = vim.fs.basename(filename)
			item.filename = filename
			item.lnum = ref.range.start.line
			item.col = ref.range.start.character
			table.insert(items, item)
		end

		local total_files = vim.tbl_count(files)
		local results_title = total .. " references in " .. total_files .. " file"
		if total_files > 1 then
			results_title = results_title .. "s"
		end

		local displayer = entry_display.create({
			separator = "",
			items = {
				{ width = 1 },
				{ remaining = true },
				{ width = 10 },
				{ width = 100 },
			},
		})

		local function make_display(entry)
			local icon, hl_group = telescope_utils.get_devicons(entry.filename, false)
			local parent = vim.fs.dirname(entry.filename)
			return displayer({
				{ icon, hl_group },
				{ " " .. entry.value.basename, "TelescopeResultsIdentifier" },
				{ ":" .. entry.lnum, "TelescopeResultsComment" },
				{ parent, "TelescopeResultsComment" },
			})
		end

		pickers
			.new({}, {
				results_title = results_title,
				initial_mode = "normal",
				finder = finders.new_table({
					results = items,
					entry_maker = function(entry)
						return {
							value = entry,
							display = make_display,
							ordinal = entry.filename,
							filename = entry.filename,
							lnum = entry.lnum + 1,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				previewer = previewers.vim_buffer_vimgrep.new({}),
			})
			:find()
	end)
end

M.commit = M.my_git_status

function M.toggle_format_on_save()
	if vim.g.disable_autoformat then
		vim.g.disable_autoformat = false
	else
		vim.g.disable_autoformat = true
	end
end

return M
