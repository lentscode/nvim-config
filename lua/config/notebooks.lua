local M = {}

function M.images_enabled()
  if #vim.api.nvim_list_uis() == 0 then return false end
  -- Can be overridden before startup, e.g. NVIM_NOTEBOOK_IMAGES=0 nvim.
  if vim.env.NVIM_NOTEBOOK_IMAGES then
    return vim.env.NVIM_NOTEBOOK_IMAGES == "1"
  end
  return vim.env.KITTY_WINDOW_ID ~= nil or vim.env.GHOSTTY_RESOURCES_DIR ~= nil
end

local function is_notebook(buf)
  return vim.api.nvim_buf_get_name(buf):match("%.ipynb$") ~= nil
end

local function start_kernel()
  local buf = vim.api.nvim_get_current_buf()
  if #vim.fn.MoltenRunningKernels(true) > 0 then
    vim.notify("This notebook already has a kernel. Use :MoltenDeinit before choosing another.")
    return
  end
  local kernels = vim.fn.MoltenAvailableKernels()
  vim.ui.select(kernels, { prompt = "Jupyter kernel:" }, function(kernel)
    if not kernel or not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.MoltenInit({ args = { kernel } })
      if is_notebook(buf) then
        -- Pass the kernel explicitly; Molten's default retry command does not escape paths with spaces.
        vim.cmd("MoltenImportOutput " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(buf)) .. " " .. vim.fn.fnameescape(kernel))
      end
    end)
  end)
end

local function create_notebook(opts, kernel)
  local path = vim.fn.fnamemodify(opts.args, ":p")
  if not path:match("%.ipynb$") then path = path .. ".ipynb" end
  local notebook = {
    nbformat = 4,
    nbformat_minor = 5,
    metadata = {
      kernelspec = { name = kernel, display_name = kernel, language = "python" },
      language_info = { name = "python", file_extension = ".py" },
    },
    cells = {
      { id = "intro", cell_type = "markdown", metadata = vim.empty_dict(), source = { "# Notebook" } },
      {
        id = "example", cell_type = "code", metadata = vim.empty_dict(),
        source = { "print(1 + 1)" }, execution_count = vim.NIL, outputs = {},
      },
    },
  }
  -- Exclusive creation prevents accidentally replacing an existing notebook.
  local fd, err = vim.uv.fs_open(path, "wx", 420)
  if not fd then error("Cannot create notebook: " .. err) end
  local written, write_err = vim.uv.fs_write(fd, vim.json.encode(notebook), 0)
  vim.uv.fs_close(fd)
  if not written then error("Cannot write notebook: " .. write_err) end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function new_notebook(opts)
  vim.ui.select(vim.fn.MoltenAvailableKernels(), { prompt = "Python kernel for the new notebook:" }, function(kernel)
    if kernel then create_notebook(opts, kernel) end
  end)
end

function M.setup()
  local bin = vim.fn.stdpath("data") .. "/jupyter-venv/bin"
  if vim.fn.executable(bin .. "/python") == 1 then
    vim.g.python3_host_prog = bin .. "/python"
    -- jupytext.nvim invokes a CLI, so it must see the same tool environment.
    vim.env.PATH = bin .. ":" .. vim.env.PATH
  end

  vim.lsp.config("pyright", {
    settings = {
      python = {
        pythonPath = vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or (bin .. "/python"),
        analysis = { diagnosticSeverityOverrides = { reportUnusedExpression = "none" } },
      },
    },
  })

  vim.api.nvim_create_user_command("NewNotebook", new_notebook, { nargs = 1, complete = "file" })
  local group = vim.api.nvim_create_augroup("NotebookWorkflow", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "markdown", "quarto" },
    callback = function(ev)
      -- Keep ordinary Markdown documents free of notebook keybindings and LSP buffers.
      if not is_notebook(ev.buf) and vim.bo[ev.buf].filetype ~= "quarto" then return end
      vim.treesitter.start(ev.buf, "markdown")
      require("quarto").activate()
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
      end
      local runner = require("quarto.runner")
      map("n", "<localleader>ni", start_kernel, "Choose notebook kernel and load saved outputs")
      map("n", "<localleader>rc", runner.run_cell, "Run cell")
      map("n", "<localleader>ra", runner.run_above, "Run cells above and current")
      map("n", "<localleader>rb", runner.run_below, "Run current cell and below")
      map("n", "<localleader>rA", runner.run_all, "Run all cells")
      map("n", "<localleader>rl", runner.run_line, "Run line")
      map("x", "<localleader>r", runner.run_range, "Run selected cells")
      map("n", "<localleader>os", "<cmd>noautocmd MoltenEnterOutput<CR>", "Enter output window")
      map("n", "<localleader>oh", "<cmd>MoltenHideOutput<CR>", "Hide output window")
      map("n", "<localleader>ox", "<cmd>MoltenOpenInBrowser<CR>", "Open rich output in browser")
      map("n", "<localleader>ri", "<cmd>MoltenInterrupt<CR>", "Interrupt kernel")
      map("n", "<localleader>rr", "<cmd>MoltenRestart<CR>", "Restart kernel")
      map("n", "]c", function() vim.fn.search("^```{\\?python", "W") end, "Next Python cell")
      map("n", "[c", function() vim.fn.search("^```{\\?python", "bW") end, "Previous Python cell")
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.ipynb",
    callback = function(ev)
      -- Jupytext writes cell sources first; only then can Molten match and save outputs.
      local kernels = vim.fn.MoltenRunningKernels(true)
      if #kernels == 1 then
        vim.cmd("MoltenExportOutput! " .. vim.fn.fnameescape(ev.file) .. " " .. vim.fn.fnameescape(kernels[1]))
      elseif #kernels > 1 then
        vim.notify("Multiple kernels attached: export outputs explicitly with :MoltenExportOutput! <path> <kernel>.", vim.log.levels.WARN)
      end
    end,
  })
end

return M
