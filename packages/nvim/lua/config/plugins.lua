return {
	{ "mturoci/diplomat.nvim" },
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		event = "BufReadPre",
		config = function()
			require("Comment").setup({
				pre_hook = function()
					return vim.bo.commentstring
				end,
			})
		end,
	},
	{ "williamboman/mason.nvim" },
	{
		"ruifm/gitlinker.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitlinker").setup({
				opts = { print_url = false },
				mappings = "<leader>ge",
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"mxsdev/nvim-dap-vscode-js",
				config = require("config.debug").setup_debug,
			},
			{
				"nvim-telescope/telescope-dap.nvim",
				config = function()
					require("telescope").load_extension("dap")
				end,
			},
			{
				"microsoft/vscode-js-debug",
				-- After install, build it and rename the dist directory to out
				build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
				version = "1.*",
			},
			{
				"rcarriga/nvim-dap-ui",
				dependencies = { "nvim-neotest/nvim-nio", "jay-babu/mason-nvim-dap.nvim" },
				config = function()
					local ui = require("dapui")
					local dap = require("dap")
					ui.setup()

					dap.listeners.before.attach.dapui_config = function()
						ui.open()
					end
					dap.listeners.before.launch.dapui_config = function()
						ui.open()
					end
					dap.listeners.before.event_terminated.dapui_config = function()
						ui.close()
					end
					dap.listeners.before.event_exited.dapui_config = function()
						ui.close()
					end
				end,
			},
		},
	},
	{ "soulsam480/nvim-oxlint", opts = {} },
	{
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup()
		end,
	},
	{ "williamboman/mason-lspconfig.nvim" },
	{ "neovim/nvim-lspconfig" },
	{ "nvim-tree/nvim-web-devicons" },
	{ "github/copilot.vim" },
	{ "tpope/vim-abolish" },
	{ "https://github.com/windwp/nvim-ts-autotag" },
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"RRethy/vim-illuminate",
		config = function()
			require("illuminate").configure({})

			vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
			vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
			vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })

			vim.api.nvim_create_autocmd({ "ColorScheme" }, {
				pattern = { "*" },
				callback = function()
					vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
					vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
					vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
				end,
			})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
				current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
		config = function()
			local conform = require("conform")

			local function get_js_formatter()
				local pkg_path = vim.fn.findfile("package.json", vim.fn.getcwd() .. ";")
				if pkg_path ~= "" then
					local content = vim.fn.readfile(pkg_path)
					local json_str = table.concat(content, "\n")
					if json_str:find('"oxfmt"') then
						return { "oxfmt" }
					end
				end
				return { "prettierd" }
			end

			local js_formatter = get_js_formatter()

			conform.setup({
				formatters_by_ft = {
					javascript = js_formatter,
					typescript = js_formatter,
					javascriptreact = js_formatter,
					typescriptreact = js_formatter,
					svelte = js_formatter,
					css = js_formatter,
					html = js_formatter,
					json = js_formatter,
					yaml = js_formatter,
					markdown = js_formatter,
					graphql = js_formatter,
					lua = { "luaformatter" },
					python = { "black" },
					php = { "blade-formatter" },
				},
				format_on_save = function()
					if vim.g.disable_autoformat then
						return
					end
					return { lsp_fallback = true, async = false, timeout_ms = 1000 }
				end,
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters.markdownlint.args = function()
				local local_config = vim.fn.findfile(".markdownlint.json", vim.fn.expand("%:p:h") .. ";")
				local config = local_config ~= "" and local_config or vim.fn.expand("~/.markdownlint.json")
				return { "--stdin", "--config", config }
			end

			local function has_oxlint()
				local pkg_path = vim.fn.findfile("package.json", vim.fn.expand("%:p:h") .. ";")
				if pkg_path ~= "" then
					local content = vim.fn.readfile(pkg_path)
					local json_str = table.concat(content, "\n")
					return json_str:find('"oxlint"')
				end
				return false
			end

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					local ft = vim.bo.filetype
					local js_fts = {
						javascript = true,
						typescript = true,
						javascriptreact = true,
						typescriptreact = true,
						svelte = true,
					}
					if js_fts[ft] and not has_oxlint() then
						lint.linters_by_ft[ft] = { "eslint_d" }
					elseif js_fts[ft] then
						lint.linters_by_ft[ft] = { "oxlint" }
					end
					lint.linters_by_ft.markdown = { "markdownlint" }
					lint.try_lint()
				end,
			})
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		branch = "master",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = false,
		config = function()
			local actions = require("telescope.actions")
			local function filename_first(_, path)
				local tail = vim.fs.basename(path)
				local parent = vim.fs.dirname(path)
				if parent == "." then
					return tail
				end
				return string.format("%s\t\t%s", tail, parent)
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "TelescopeResults",
				callback = function(ctx)
					vim.api.nvim_buf_call(ctx.buf, function()
						vim.fn.matchadd("TelescopeParent", "\t\t.*$")
						vim.api.nvim_set_hl(0, "TelescopeParent", { link = "TelescopeResultsComment" })
					end)
				end,
			})

			require("telescope").setup({
				pickers = {
					find_files = {
						find_command = { "rg", "--files", "--hidden", "-g", "!**/.git/*" },
					},
					live_grep = {
						additional_args = function(_)
							return { "--hidden", "-g", "!**/.git/*" }
						end,
					},
				},
				defaults = {
					mappings = {
						n = {
							["<CR>"] = actions.select_default + actions.center,
							["<M-CR>"] = actions.select_vertical + actions.center,
							["<C-q>"] = actions.send_to_qflist,
						},
						i = {
							["<CR>"] = actions.select_default + actions.center,
							["<M-CR>"] = actions.select_vertical + actions.center,
							["<C-q>"] = actions.send_to_qflist,
						},
					},
					sorting_strategy = "ascending",
					layout_config = { prompt_position = "top", preview_width = 0.65 },
					prompt_prefix = " ",
					-- TODO: Doesn't work for git_status. Needs to be fixed in telescope itself.
					path_display = filename_first,
				},
			})
		end,
	},
	{
		"natecraddock/telescope-zf-native.nvim",
		config = function()
			require("telescope").load_extension("zf-native")
		end,
	},
	{
		"stevearc/oil.nvim",
		opts = {},
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				skip_confirm_for_simple_edits = true,
        columns = {
          "icon",
          "size",
        },
				lsp_file_methods = {
					timeout_ms = 1000,
					autosave_changes = true,
				},
				view_options = {
					show_hidden = true,
				},
				confirmation = {
					border = "rounded",
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"css",
					"python",
					"go",
					"javascript",
					"typescript",
					"html",
					"svelte",
					"json",
					"markdown",
					"tsx",
				},
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },
				autotag = { enable = true, enable_rename = true },
			})
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
			"hrsh7th/cmp-buffer", -- source for text in buffer
			"hrsh7th/cmp-path", -- source for file system paths
			"L3MON4D3/LuaSnip",
			-- snippet engine
			"saadparwaiz1/cmp_luasnip", -- for autocompletion
			"rafamadriz/friendly-snippets", -- useful snippets
			"onsails/lspkind.nvim", -- vs-code like pictograms
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			-- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				completion = { completeopt = "menu,menuone,preview" },
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				snippet = { -- configure how nvim-cmp interacts with snippet engine
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
					["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
					["<C-e>"] = cmp.mapping.abort(), -- close completion window
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				-- sources for autocompletion
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "path" }, -- file system paths
				}),
				formatting = {
					fields = { "abbr", "kind" },
					format = function(entry, vim_item)
						vim_item.kind = lspkind.presets.default[vim_item.kind]
						vim_item.menu = nil
						return vim_item
					end,
				},
			})
		end,
	},
}
