-- Impostazioni base
vim.g.mapleader = " "

-- Eliminate ESC delay
vim.o.ttimeoutlen = 0

-- Opzioni
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.ignorecase = true
vim.o.winborder = "rounded"
vim.o.relativenumber = true
vim.o.smarttab = true
vim.o.smartindent = true
vim.o.swapfile = false
vim.o.signcolumn = "yes"
vim.o.statusline = "%f%m%r%h%=[%{&filetype}]%l,%c%p%%"
vim.cmd.colorscheme("mine")

-- CamelCaseMotion mappings
-- vim.keymap.set({"n", "v", "o"}, "w", "<Plug>CamelCaseMotion_w")
-- vim.keymap.set({"n", "v", "o"}, "b", "<Plug>CamelCaseMotion_b")
-- vim.keymap.set({"n", "v", "o"}, "e", "<Plug>CamelCaseMotion_e")

-- File operations
vim.keymap.set('n', 'ff', '<cmd>FzfLua git_files<CR>', { desc = 'Find files' })
vim.keymap.set('n', 'fj', '<cmd>FzfLua jj_files<CR>', { desc = 'Find files (jj)' })

vim.lsp.config("*", {
	root_markers = { ".git" },
	on_attach = function(client, bufnr)
		vim.lsp.completion.enable(true, client.id, bufnr, {
			convert = function(item)
				return { abbr = item.label:gsub("%b()", "") }
			end,
		})
	end,
})
-- vim.lsp.inlay_hint.enable(true)

require("config.lazy")
require("config.angular")
