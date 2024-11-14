vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.opt.laststatus = 3
vim.cmd("language en_US")
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- イベントベースの自動保存
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
	pattern = { "*" },
	command = "silent! write",
})

vim.api.nvim_create_user_command("AI", function()
	local filename = vim.fn.expand("%:p")

	if vim.fn.expand("%:e") ~= "md" then
		vim.notify("This command works only with Markdown files", vim.log.levels.ERROR)
		return
	end
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = ""
	local last_separator = -1
	for i = #lines, 1, -1 do
		if lines[i] == "---" then
			last_separator = i
			break
		end
	end

	if last_separator > -1 then
		content = table.concat(lines, "\n", last_separator + 1)
	else
		content = table.concat(lines, "\n")
	end

	local temp_in = os.tmpname()
	local f = io.open(temp_in, "w")
	if f then
		f:write(content)
		f:close()
	end

	local cmd
	if last_separator > -1 then
		cmd = string.format("base64 -i %s | base64 -d | llm -c", temp_in)
	else
		cmd = string.format("base64 -i %s | base64 -d | llm", temp_in)
	end
	local f = io.open(filename, "a")
	f:write("\n---\n\n")

	local output = vim.fn.system(cmd)
	f:write(output)
	f:write("\n\n---\n")

	f:close()
	vim.cmd("edit!")
end, {})

local function run_rspec_in_tmux(command)
	local tmux_command = string.format("tmux split-window -h 'cd %s && %s; $SHELL'", vim.fn.getcwd(), command)
	vim.fn.system(tmux_command)
end

local function run_rspec(target_type)
	local commands = {
		file = "bundle exec rspec " .. vim.fn.expand("%"),
		line = "bundle exec rspec " .. vim.fn.expand("%") .. ":" .. vim.fn.line("."),
		suite = "bundle exec rspec",
	}

	local command = commands[target_type]
	if command then
		vim.g.last_rspec_command = command
		run_rspec_in_tmux(command)
	end
end

vim.keymap.set("n", "<Leader>rf", function()
	run_rspec("file")
end)

vim.keymap.set("n", "<Leader>rl", function()
	run_rspec("line")
end)

vim.keymap.set("n", "<Leader>ra", function()
	run_rspec("suite")
end)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	{ "cohama/lexima.vim" },
	{ "numToStr/Comment.nvim" },
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- set this if you want to always pull the latest change
		opts = {
			-- add any opts here
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
	{
		"FabijanZulj/blame.nvim",
		lazy = false,
		config = function()
			require("blame").setup({})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				numhl = true,
				linehl = false,
				word_diff = false,
				watch_gitdir = {
					interval = 1000,
					follow_files = true,
				},
				attach_to_untracked = true,
				current_line_blame = false,
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol",
					delay = 0,
					ignore_whitespace = false,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
				sign_priority = 6,
				update_debounce = 100,
				status_formatter = nil,
				max_file_length = 40000,
				preview_config = {
					border = "single",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })
					map("n", "<leader>hs", gs.stage_hunk)
					map("n", "<leader>hr", gs.reset_hunk)
					map("v", "<leader>hs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)
					map("v", "<leader>hr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)
					map("n", "<leader>hS", gs.stage_buffer)
					map("n", "<leader>hu", gs.undo_stage_hunk)
					map("n", "<leader>hR", gs.reset_buffer)
					map("n", "<leader>hp", gs.preview_hunk)
					map("n", "<leader>hb", function()
						gs.blame_line({ full = true })
					end)
					map("n", "<leader>tb", gs.toggle_current_line_blame)
					map("n", "<leader>hd", gs.diffthis)
					map("n", "<leader>hD", function()
						gs.diffthis("~")
					end)
					map("n", "<leader>td", gs.toggle_deleted)
				end,
			})
		end,
	},
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- calling `setup` is optional for customization
			require("fzf-lua").setup({})
		end,
	},
	{ "nvim-telescope/telescope.nvim", tag = "0.1.8", dependencies = { "nvim-lua/plenary.nvim" } },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({ style = "moon", transparent = true })
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{
		"hrsh7th/nvim-cmp",
	},
	{ "sindrets/diffview.nvim" },
	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.prettier.with({
						filetypes = {
							"javascript",
							"javascriptreact",
							"typescript",
							"typescriptreact",
							"vue",
							"css",
							"scss",
							"less",
							"html",
							"json",
							"jsonc",
							"yaml",
							"markdown",
							"graphql",
						},
					}),
				},
			})
			vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format document" })
			local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = {
					"*.ts",
					"*.tsx",
					"*.js",
					"*.jsx",
					"*.vue",
					"*.css",
					"*.scss",
					"*.json",
					"*.md",
					"*.lua",
				},
				callback = function()
					vim.lsp.buf.format()
				end,
				group = group,
			})
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"tsserver",
				"prettier",
				"markman",
			},
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = true,
		opts = {
			auto_install = true,
		},
		dependencies = {
			"williamboman/mason.nvim",
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("mason").setup()
			require("mason-lspconfig").setup()
			require("lspconfig").marksman.setup({
				capabilities = capabilities,
				filetypes = { "markdown", "markdown.mdx" },
				root_dir = require("lspconfig.util").root_pattern(".git", ".marksman.toml"),
			})
			require("lspconfig").rubocop.setup({})
			require("lspconfig").solargraph.setup({
				capabilities = capabilities,
				filetypes = { "ruby" },
				root_dir = require("lspconfig.util").root_pattern(".git"),
				on_attach = function(client, bufnr)
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			})
			require("lspconfig").ts_ls.setup({
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-buffer",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
				},
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
				},
			})
		end,
	},
}
local opts = {}

require("lazy").setup(plugins, opts)

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>")

local configs = require("nvim-treesitter.configs")

configs.setup({
	ensure_installed = { "lua", "ruby", "javascript", "html" },
	highlight = { enable = true },
	indent = { enable = true },
	endwise = { enable = true },
})
vim.opt.termguicolors = true
vim.opt.background = "dark"
