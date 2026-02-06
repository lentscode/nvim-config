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

-- Delete trailing whitespaces
vim.keymap.set("n", "<F5>", ":let _s=@/<Bar>:%s/\\s\\+$//e<Bar>:let @/=_s<Bar><CR>")

-- CoC configuration
vim.keymap.set("i", "<CR>", "coc#pum#visible() ? coc#pum#confirm() : '<CR>'", {expr = true, silent = true})

-- Highlight groups per CoC
vim.cmd([[
  highlight CocInlayHint ctermfg=12 ctermbg=0 cterm=italic
  highlight CocFloating ctermfg=1 ctermbg=0
]])

-- Documentation function
vim.keymap.set("n", "K", ":call ShowDocumentation()<CR>", {silent = true})

-- Floating window scroll
vim.keymap.set("n", "<C-f>", 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', {expr = true, silent = true})
vim.keymap.set("n", "<C-b>", 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', {expr = true, silent = true})

-- Vimrc operations
vim.keymap.set("n", "_v", ":e $MYVIMRC<CR>")
vim.keymap.set("n", "_u", ":source $MYVIMRC<CR>")

-- Funzione per documentazione
vim.cmd([[
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
]])

require("config.lazy")
