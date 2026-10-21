local M = {}
local api = vim.api
local popup = require("plenary.popup")
local illuminate = require("illuminate")
local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local telescope_utils = require("telescope.utils")
local entry_display = require("telescope.pickers.entry_display")
local utils = require("config.utils")

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

function M.toggle_format_on_save()
	if vim.g.disable_autoformat then
		vim.g.disable_autoformat = false
	else
		vim.g.disable_autoformat = true
	end
end

return M
