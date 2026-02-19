-- Impostazioni base
vim.g.mapleader = " "

-- Opzioni
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.smarttab = true
vim.opt.tabstop = 2
vim.opt.statusline = "%f%m%r%h%=[%{&filetype}]%l,%c%p%%"
vim.cmd.colorscheme("mine")

-- CamelCaseMotion mappings
vim.keymap.set({"n", "v", "o"}, "w", "<Plug>CamelCaseMotion_w")
vim.keymap.set({"n", "v", "o"}, "b", "<Plug>CamelCaseMotion_b")
vim.keymap.set({"n", "v", "o"}, "e", "<Plug>CamelCaseMotion_e")

-- File operations
vim.keymap.set('n', 'ff', '<cmd>FzfLua files<CR>', { desc = 'Find files' })

vim.lsp.enable("gopls")

require("config.lazy")
