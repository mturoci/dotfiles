local M = {}
local api = vim.api
local illuminate = require("illuminate")
local previewers = require("telescope.previewers")
local previewer_utils = require("telescope.previewers.utils")
local pickers = require("telescope.pickers")
local builtin = require("telescope.builtin")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
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
		minidiff.goto_hunk(direction, { wrap = false })

		local first = data.hunks[1]
		if vim.fn.line(".") == 1 and first.buf_start <= 1 then
			-- Old lines above line 1 are only visible as filler.
			vim.fn.winrestview({ topline = 1, topfill = first.ref_count })
		else
			vim.cmd("normal! zz")
		end
	end)
end

-- Icon and highlight for a git file status letter (M, A, D, ...).
local function status_icon(status)
	if status == "U" then
		return "", "DiagnosticError"
	elseif status == "M" then
		return "", "GitSignsChange"
	elseif status == "A" or status == "?" then
		return "", "GitSignsAdd"
	elseif status == "D" then
		return "", "GitSignsDelete"
	end
	return "  ", "TelescopeResultsComment"
end

-- Debounced previewer for changed files. `get_spec(entry)` describes what to show:
--   { path = abs_path }                          the file on disk
--   { filename = name, lines = {}, base = {} }   given content, with the changes against `base` marked on top if set
--   { command = {} }                             terminal command, e.g. a delta diff
local function changes_previewer(get_spec)
	local spec

	local term_previewer = previewers.new_termopen_previewer({
		get_command = function()
			return spec.command
		end,
	})

	local buffer_previewer = previewers.new_buffer_previewer({
		define_preview = function(self, _, status)
			local current = spec
			if current.path then
				conf.buffer_previewer_maker(current.path, self.state.bufnr, {
					bufname = self.state.bufname,
					winid = self.state.winid,
				})
				return
			end

			api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, current.lines)
			previewer_utils.highlighter(self.state.bufnr, previewer_utils.filetype_detect(current.filename))

			if current.base then
				local bufnr = self.state.bufnr
				show_changes(bufnr, current.base, function()
					-- Start on the first change, unless another file got previewed in the meantime.
					if api.nvim_win_is_valid(status.preview_win) and api.nvim_win_get_buf(status.preview_win) == bufnr then
						goto_preview_hunk(status.prompt_bufnr, "next")
					end
				end)
			end
		end,
	})

	local preview_timer

	return previewers.Previewer:new({
		preview_fn = function(self, entry, status)
			local function render()
				spec = get_spec(entry)
				self.state.current = spec.command and term_previewer or buffer_previewer
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
			buffer_previewer:teardown()
			term_previewer:teardown()
		end,
	})
end

-- Telescope jumps the results window to the top after every refresh, keep the scroll position instead.
-- The selected row stays with `selection_strategy = "row"`, `opts.select(entry)` picks another entry.
local function refresh_picker(picker, finder, opts)
	opts = opts or {}
	picker.pending_view = {
		topline = api.nvim_win_call(picker.results_win, vim.fn.winsaveview).topline,
		select = opts.select,
	}
	picker:refresh(finder, { reset_prompt = opts.reset_prompt })
end

local function restore_view_after_refresh(picker)
	picker:register_completion_callback(function(p)
		local view = p.pending_view
		if not view or not api.nvim_win_is_valid(p.results_win) then
			return
		end
		p.pending_view = nil

		if view.select then
			local index = 0
			for entry in p.manager:iter() do
				index = index + 1
				if view.select(entry) then
					p:set_selection(p:get_row(index))
					return
				end
			end
		end
		api.nvim_win_call(p.results_win, function()
			vim.fn.winrestview({ topline = view.topline, lnum = p:get_selection_row() + 1, col = 0 })
		end)
	end)
end

-- Selection and preview hunk navigation shared by the git pickers.
local function map_navigation(prompt_bufnr, map)
	-- Like j/k, but skip three entries at a time.
	map({ "n" }, "J", function()
		action_set.shift_selection(prompt_bufnr, 3)
	end)

	map({ "n" }, "K", function()
		action_set.shift_selection(prompt_bufnr, -3)
	end)

	map({ "n" }, "<C-h>", function()
		goto_preview_hunk(prompt_bufnr, "next")
	end)

	map({ "n" }, "<S-h>", function()
		goto_preview_hunk(prompt_bufnr, "prev")
	end)
end

local delta_bcommits = previewers.new_termopen_previewer({
	get_command = function(entry)
		return git_delta({ "diff", entry.value .. "^!", "--", entry.current_file })
	end,
})

M.status = function(opts)
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

		local icon, icon_hl = status_icon(entry.value.is_staged and entry.value.staged_status or entry.value.unstaged_status)

		return displayer({
			{
				staged_icon,
				entry.value.is_staged and "GitSignsAdd" or "TelescopeResultsComment",
			},
			{ icon, icon_hl },
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

	local function refresh(prompt_bufnr)
		local new_finder = create_finder()
		if not new_finder then
			actions.close(prompt_bufnr)
			illuminate.toggle()
			return false
		end
		refresh_picker(action_state.get_current_picker(prompt_bufnr), new_finder)
		return true
	end

	-- TODO: Maybe displaying initial empty is fine?
	local finder = create_finder()
	if not finder then
		return
	end

	-- Show new, modified and conflicted files as nvim buffers (changes marked on top), delta covers the rest.
	local previewer = changes_previewer(function(entry)
		local value = entry.value
		local file_status = value.is_staged and value.staged_status or value.unstaged_status
		if file_status == "D" then
			return { command = { "echo", "The file was deleted." } }
		end
		if file_status ~= "A" and file_status ~= "?" and file_status ~= "M" and file_status ~= "U" then
			local args = value.is_staged and { "diff", "--staged", value.filename } or { "diff", value.filename }
			return { command = git_delta(args) }
		end
		if not value.is_staged and file_status ~= "M" then
			return { path = value.abs_path }
		end

		return {
			filename = value.filename,
			-- Show the staged content for staged rows, the working tree version may have changed since.
			lines = value.is_staged and git_show(":./" .. value.filename) or vim.fn.readfile(value.abs_path),
			base = file_status == "M" and git_show((value.is_staged and "HEAD:./" or ":./") .. value.filename) or nil,
		}
	end)

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

			map_navigation(prompt_bufnr, map)

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

	restore_view_after_refresh(picker)

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

-- Commit log where <tab> expands a commit's changed files underneath it and <CR> narrows the picker down to them.
M.commits = function(opts)
	local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
	if vim.v.shell_error ~= 0 then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end

	local commits = {}
	for _, line in ipairs(vim.fn.systemlist({ "git", "log", "--format=%h%x09%an%x09%s" })) do
		local sha, author, subject = line:match("^(%S+)\t([^\t]*)\t(.*)$")
		if sha then
			table.insert(commits, { sha = sha, author = author, subject = subject })
		end
	end
	if #commits == 0 then
		return
	end

	-- Merge commits are compared against their first parent, renames show up as a deletion and an addition.
	local files_cache = {}
	local function get_commit_files(sha)
		if files_cache[sha] then
			return files_cache[sha]
		end
		local show = { "git", "show", "--format=", "--diff-merges=first-parent", "--no-renames" }
		local stats = {}
		for _, line in ipairs(vim.fn.systemlist(vim.list_extend(vim.list_extend({}, show), { "--numstat", sha }))) do
			local additions, deletions, path = line:match("^(%S+)\t(%S+)\t(.+)$")
			if path then
				stats[path] = { additions = additions, deletions = deletions }
			end
		end

		local files = {}
		for _, line in ipairs(vim.fn.systemlist(vim.list_extend(vim.list_extend({}, show), { "--name-status", sha }))) do
			local status, path = line:match("^(%a)%S*\t(.+)$")
			if path then
				local stat = stats[path] or { additions = "-", deletions = "-" }
				table.insert(files, {
					sha = sha,
					status = status,
					path = path,
					additions = stat.additions,
					deletions = stat.deletions,
				})
			end
		end
		files_cache[sha] = files
		return files
	end

	local commit_displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 1 },
			{ width = 10 },
			{ remaining = true },
			{ remaining = true },
		},
	})

	local function make_file_displayer(indent)
		return entry_display.create({
			separator = "",
			items = {
				{ width = indent + 2 },
				{ width = 6, right_justify = true },
				{ width = 6, right_justify = true },
				{ remaining = true },
				{ remaining = true },
			},
		})
	end
	local file_displayer = make_file_displayer(0)
	local nested_file_displayer = make_file_displayer(4)

	local expanded = {}
	-- Sha of the commit whose files fill the picker, nil while showing the log.
	local current_commit

	local function commit_entry(commit)
		return {
			kind = "commit",
			value = commit,
			ordinal = commit.sha .. " " .. commit.subject .. " " .. commit.author,
			display = function()
				return commit_displayer({
					{ expanded[commit.sha] and "▾" or "▸", "TelescopeResultsComment" },
					{ commit.sha, "TelescopeResultsCommitHash" },
					{ commit.subject, "TelescopeResultsIdentifier" },
					{ commit.author, "TelescopeResultsComment" },
				})
			end,
		}
	end

	local function file_entry(file, parent)
		local indent = parent and 4 or 0
		local displayer = parent and nested_file_displayer or file_displayer
		return {
			kind = "file",
			value = file,
			filename = root .. "/" .. file.path,
			-- Nested files keep matching the filter of their commit.
			ordinal = (parent and parent.ordinal .. " " or "") .. file.path,
			display = function()
				local icon, icon_hl = status_icon(file.status)
				local parent_dir = vim.fs.dirname(file.path)
				return displayer({
					{ string.rep(" ", indent) .. icon, icon_hl },
					{ "+" .. file.additions, "GitSignsAdd" },
					{ "-" .. file.deletions .. " ", "GitSignsDelete" },
					{ " " .. vim.fs.basename(file.path) .. " ", "TelescopeResultsIdentifier" },
					{ parent_dir ~= "." and parent_dir or "", "TelescopeResultsComment" },
				})
			end,
		}
	end

	local function create_finder()
		local results = {}
		if current_commit then
			for _, file in ipairs(get_commit_files(current_commit)) do
				table.insert(results, file_entry(file))
			end
		else
			for _, commit in ipairs(commits) do
				local entry = commit_entry(commit)
				table.insert(results, entry)
				if expanded[commit.sha] then
					for _, file in ipairs(get_commit_files(commit.sha)) do
						table.insert(results, file_entry(file, entry))
					end
				end
			end
		end
		return finders.new_table({
			results = results,
			entry_maker = function(entry)
				return entry
			end,
		})
	end

	-- Commits show their stats, files are previewed the same way as in the git status.
	local previewer = changes_previewer(function(entry)
		local value = entry.value
		if entry.kind == "commit" then
			return {
				command = git_delta({ "show", "--stat", "--summary", "--format=fuller", "--diff-merges=first-parent", value.sha }),
			}
		end
		if value.status == "A" or value.status == "M" then
			return {
				filename = value.path,
				lines = git_show(value.sha .. ":" .. value.path),
				base = value.status == "M" and git_show(value.sha .. "^:" .. value.path) or nil,
			}
		end
		return { command = git_delta({ "-C", root, "diff", value.sha .. "^", value.sha, "--", value.path }) }
	end)

	-- Open the file as of its commit in a read-only scratch buffer, deleted files as of right before the commit.
	local function open_commit_version(file)
		local object = file.sha .. (file.status == "D" and "^" or "") .. ":" .. file.path
		local existing = vim.fn.bufnr(object)
		if existing ~= -1 then
			api.nvim_set_current_buf(existing)
			return
		end
		local bufnr = api.nvim_create_buf(false, true)
		api.nvim_buf_set_name(bufnr, object)
		vim.bo[bufnr].bufhidden = "wipe"
		api.nvim_buf_set_lines(bufnr, 0, -1, false, git_show(object))
		vim.bo[bufnr].modifiable = false
		vim.bo[bufnr].modified = false
		api.nvim_set_current_buf(bufnr)
		-- Treesitter highlighting attaches on FileType.
		vim.bo[bufnr].filetype = vim.filetype.match({ filename = file.path }) or ""
	end

	local function set_title(picker)
		picker.prompt_border:change_title(current_commit and ("Commit " .. current_commit) or "Git Log")
	end

	-- Narrow the picker down to the files of `sha`, selecting `path` if given.
	local function open_commit(picker, sha, path)
		current_commit = sha
		set_title(picker)
		refresh_picker(picker, create_finder(), {
			reset_prompt = true,
			select = function(entry)
				return not path or entry.value.path == path
			end,
		})
	end

	local picker = pickers.new(opts or {}, {
		prompt_title = "Git Log",
		initial_mode = "normal",
		layout_config = { width = { padding = 0 }, height = { padding = 0 } },
		-- Keep the cursor on the same row when a commit gets expanded or collapsed.
		selection_strategy = "row",
		finder = create_finder(),
		-- Filters without reordering, so files stay under their commit.
		sorter = require("telescope.sorters").get_substr_matcher(),
		previewer = previewer,
		attach_mappings = function(prompt_bufnr, map)
			map({ "i", "n" }, "<tab>", function()
				local entry = action_state.get_selected_entry()
				if not entry or current_commit then
					return
				end

				local picker = action_state.get_current_picker(prompt_bufnr)
				if entry.kind == "commit" then
					expanded[entry.value.sha] = not expanded[entry.value.sha]
					refresh_picker(picker, create_finder())
				else
					-- Collapse the commit the file belongs to.
					local sha = entry.value.sha
					expanded[sha] = nil
					refresh_picker(picker, create_finder(), {
						select = function(e)
							return e.kind == "commit" and e.value.sha == sha
						end,
					})
				end
			end)

			-- Back from the commit files to the log.
			map({ "n" }, "<BS>", function()
				if not current_commit then
					return
				end
				local sha = current_commit
				current_commit = nil
				local picker = action_state.get_current_picker(prompt_bufnr)
				set_title(picker)
				refresh_picker(picker, create_finder(), {
					reset_prompt = true,
					select = function(entry)
						return entry.kind == "commit" and entry.value.sha == sha
					end,
				})
			end)

			map_navigation(prompt_bufnr, map)

			actions.select_default:replace(function()
				local entry = action_state.get_selected_entry()
				if not entry then
					return
				end

				local picker = action_state.get_current_picker(prompt_bufnr)
				if entry.kind == "commit" then
					open_commit(picker, entry.value.sha)
				elseif not current_commit then
					open_commit(picker, entry.value.sha, entry.value.path)
				else
					actions.close(prompt_bufnr)
					open_commit_version(entry.value)
				end
			end)

			return true
		end,
	})

	restore_view_after_refresh(picker)
	picker:find()
end

M.bcommits = function(opts)
	opts = opts or {}
	opts.previewer = {
		delta_bcommits,
		previewers.git_commit_message.new(opts),
		previewers.git_commit_diff_as_was.new(opts),
	}

	builtin.git_bcommits(opts)
end

M.commit = M.status

-- Shared with the other tree pickers, e.g. tickets.
M.refresh_picker = refresh_picker
M.restore_view_after_refresh = restore_view_after_refresh
M.map_navigation = map_navigation

return M
