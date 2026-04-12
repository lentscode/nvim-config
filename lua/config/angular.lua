-- Angular component layout automation
-- Detects Angular components by checking if the current file's base name has
-- siblings with .ts, .html, and .scss/.css in the same directory.
--
-- Layout when inside a component:
--   Left column:  HTML (top) + SCSS/CSS (bottom)
--   Right column: TypeScript (full height, focused)
--
-- When a non-component file is opened, collapses to a single full-screen window.

local setting_up = false
local current_base = nil  -- "dir/name" of the component currently displayed

-- Returns the component base path ("dir/name") if fp is part of an Angular
-- component, or nil otherwise.
local function component_base(fp)
  local ext = vim.fn.fnamemodify(fp, ":e")
  if ext ~= "ts" and ext ~= "html" and ext ~= "scss" and ext ~= "css" then
    return nil
  end

  local dir  = vim.fn.fnamemodify(fp, ":h")
  local name = vim.fn.fnamemodify(fp, ":t:r")
  local base = dir .. "/" .. name

  local has_ts    = vim.fn.filereadable(base .. ".ts")   == 1
  local has_html  = vim.fn.filereadable(base .. ".html") == 1
  local has_style = vim.fn.filereadable(base .. ".scss") == 1
                 or vim.fn.filereadable(base .. ".css")  == 1

  if has_ts and has_html and has_style then
    return base
  end
  return nil
end

local function open_layout(base)
  local ts    = base .. ".ts"
  local html  = base .. ".html"
  local style = vim.fn.filereadable(base .. ".scss") == 1 and base .. ".scss"
             or base .. ".css"

  setting_up = true

  -- Single window to start
  vim.cmd("only")

  -- Right side: TypeScript (stays in the current window)
  vim.cmd("edit " .. vim.fn.fnameescape(ts))

  -- Left column: HTML on top, style on bottom
  vim.cmd("leftabove vsplit")
  vim.cmd("edit " .. vim.fn.fnameescape(html))
  vim.cmd("rightbelow split " .. vim.fn.fnameescape(style))

  -- Focus the TypeScript window
  vim.cmd("wincmd l")

  setting_up = false
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("AngularLayout", { clear = true }),
  callback = function(ev)
    if setting_up then return end

    local fp = vim.api.nvim_buf_get_name(ev.buf)
    if fp == "" then return end

    -- Ignore special/tool buffers (quickfix, terminal, etc.)
    if vim.bo[ev.buf].buftype ~= "" then return end

    local base = component_base(fp)

    if base then
      -- Already showing this component — nothing to do
      if base == current_base then return end

      current_base = base
      vim.schedule(function()
        open_layout(base)
      end)
    elseif current_base ~= nil then
      -- Leaving the Angular layout — collapse to full screen
      current_base = nil
      vim.schedule(function()
        setting_up = true
        vim.cmd("only")
        setting_up = false
      end)
    end
  end,
})
