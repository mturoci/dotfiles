local M = {}
local api = vim.api
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local git = require("config.git")

-- Icon and highlight for a `tk ls` status mark.
local function status_icon(mark)
	if mark == "~" then
		return "", "GitSignsChange"
	elseif mark == "x" then
		return "", "GitSignsAdd"
	elseif mark == "a" then
		return "", "TelescopeResultsComment"
	end
	return "", "TelescopeResultsIdentifier"
end

-- Ticket tree of the nearest `.tickets` dir (see `tk help`), where <tab> expands a ticket's children underneath it
-- and <CR> opens the ticket's markdown file.
M.tickets = function(opts)
	local dir = vim.fs.find(".tickets", { upward = true, type = "directory", path = vim.fn.getcwd() })[1]
	if not dir then
		vim.notify("No .tickets directory found", vim.log.levels.WARN)
		return
	end

	local function tk(args)
		local output = vim.fn.systemlist(vim.list_extend({ "tk", "--dir", dir }, args))
		if vim.v.shell_error ~= 0 then
			vim.notify(table.concat(output, "\n"), vim.log.levels.ERROR)
			return nil
		end
		return output
	end

	-- Closed and archived tickets are listed too, <M-a> toggles them off.
	local show_all = true

	-- Done tickets sink below their open siblings, archived ones below the closed ones.
	local mark_rank = { x = 1, a = 2 }

	-- Flatten the tree back into rows, ordering each level's siblings by `mark_rank`.
	local function flatten(siblings, rows)
		local ordered = {}
		for index, ticket in ipairs(siblings) do
			ordered[index] = { ticket = ticket, index = index }
		end
		table.sort(ordered, function(a, b)
			local rank_a, rank_b = mark_rank[a.ticket.mark] or 0, mark_rank[b.ticket.mark] or 0
			if rank_a ~= rank_b then
				return rank_a < rank_b
			end
			return a.index < b.index
		end)
		for _, item in ipairs(ordered) do
			table.insert(rows, item.ticket)
			flatten(item.ticket.children, rows)
		end
		return rows
	end

	-- Parse `tk ls` lines like `  3.1 [~] ipase4  [task/normal] Title  <- blocker`, in tree order.
	local function get_tickets()
		local roots = {}
		-- Latest ticket at each depth, the parent of the deeper ones that follow.
		local parents = {}
		for _, line in ipairs(tk(show_all and { "ls", "--archived" } or { "ls" }) or {}) do
			local indent, position, mark, id, kind, rest = line:match("^(%s*)(%S+) %[(.)%] (%S+)  %[([^%]]+)%] (.*)$")
			if id then
				local title, blockers = rest:match("^(.-)  <%- (.*)$")
				local ticket = {
					id = id,
					depth = #indent / 2,
					position = position,
					mark = mark,
					kind = kind,
					title = title or rest,
					blockers = blockers,
					children = {},
				}
				local parent = parents[ticket.depth - 1]
				if parent then
					parent.has_children = true
				end
				table.insert(parent and parent.children or roots, ticket)
				parents[ticket.depth] = ticket
			end
		end
		return flatten(roots, {})
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ remaining = true },
			{ width = 2 },
			{ width = 6 },
			{ remaining = true },
			{ remaining = true },
			{ remaining = true },
		},
	})

	local expanded = {}
	local tickets = get_tickets()

	local function ticket_entry(ticket, parent)
		local icon, icon_hl = status_icon(ticket.mark)
		local arrow = ticket.has_children and (expanded[ticket.id] and "▾" or "▸") or " "
		return {
			value = ticket,
			filename = dir .. "/" .. ticket.id .. ".md",
			-- Nested tickets keep matching the filter of their parent.
			ordinal = (parent and parent.ordinal .. " " or "") .. ticket.id .. " " .. ticket.title .. " " .. ticket.kind,
			display = function()
				return displayer({
					{ string.rep("  ", ticket.depth) .. arrow, "TelescopeResultsComment" },
					{ icon, icon_hl },
					{ ticket.id, "TelescopeResultsCommitHash" },
					{ ticket.title, "TelescopeResultsIdentifier" },
					{ ticket.kind, "TelescopeResultsComment" },
					{ ticket.blockers and ("<- " .. ticket.blockers) or "", "DiagnosticWarn" },
				})
			end,
		}
	end

	local function create_finder()
		local results = {}
		-- Entries of the visible ancestors, indexed by depth.
		local parents = {}
		-- Depth of the collapsed ticket whose descendants are skipped.
		local collapsed_depth
		for _, ticket in ipairs(tickets) do
			if collapsed_depth and ticket.depth > collapsed_depth then
				goto continue
			end
			collapsed_depth = nil

			local entry = ticket_entry(ticket, parents[ticket.depth - 1])
			parents[ticket.depth] = entry
			table.insert(results, entry)
			if ticket.has_children and not expanded[ticket.id] then
				collapsed_depth = ticket.depth
			end
			::continue::
		end
		return finders.new_table({
			results = results,
			entry_maker = function(entry)
				return entry
			end,
		})
	end

	local function select_id(id)
		return function(entry)
			return entry.value.id == id
		end
	end

	local function reload(picker, select)
		tickets = get_tickets()
		git.refresh_picker(picker, create_finder(), { select = select })
	end

	local function set_title(picker)
		picker.prompt_border:change_title(show_all and "Tickets" or "Tickets (open)")
	end

	-- Run `tk <command> <id>` on the selected ticket and keep it selected if it's still listed.
	local function map_command(map, prompt_bufnr, lhs, command)
		map({ "n" }, lhs, function()
			local entry = action_state.get_selected_entry()
			if not entry then
				return
			end
			if tk({ command, entry.value.id }) then
				reload(action_state.get_current_picker(prompt_bufnr), select_id(entry.value.id))
			end
		end)
	end

	local picker = pickers.new(opts or {}, {
		prompt_title = "Tickets",
		initial_mode = "normal",
		layout_config = { width = { padding = 0 }, height = { padding = 0 } },
		-- Keep the cursor on the same row when a ticket gets expanded or collapsed.
		selection_strategy = "row",
		finder = create_finder(),
		-- Filters without reordering, so tickets stay under their parent.
		sorter = require("telescope.sorters").get_substr_matcher(),
		previewer = conf.file_previewer({}),
		attach_mappings = function(prompt_bufnr, map)
			map({ "i", "n" }, "<tab>", function()
				local entry = action_state.get_selected_entry()
				if not entry then
					return
				end

				local picker = action_state.get_current_picker(prompt_bufnr)
				local ticket = entry.value
				if ticket.has_children then
					expanded[ticket.id] = not expanded[ticket.id]
					git.refresh_picker(picker, create_finder())
					return
				end

				-- Collapse the parent of a leaf, the closest shallower ticket listed above it.
				local parent
				for _, t in ipairs(tickets) do
					if t.id == ticket.id then
						break
					end
					if t.depth < ticket.depth then
						parent = t
					end
				end
				if parent then
					expanded[parent.id] = nil
					git.refresh_picker(picker, create_finder(), { select = select_id(parent.id) })
				end
			end)

			map({ "n" }, "<M-a>", function()
				local entry = action_state.get_selected_entry()
				local picker = action_state.get_current_picker(prompt_bufnr)
				show_all = not show_all
				set_title(picker)
				reload(picker, entry and select_id(entry.value.id))
			end)

			map_command(map, prompt_bufnr, "<M-s>", "start")
			map_command(map, prompt_bufnr, "<M-c>", "close")
			map_command(map, prompt_bufnr, "<M-o>", "reopen")

			git.map_navigation(prompt_bufnr, map)

			actions.select_default:replace(function()
				local entry = action_state.get_selected_entry()
				if not entry then
					return
				end
				actions.close(prompt_bufnr)
				vim.cmd.edit(vim.fn.fnameescape(entry.filename))
			end)

			return true
		end,
	})

	git.restore_view_after_refresh(picker)
	picker:find()
end

return M
