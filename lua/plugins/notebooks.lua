return {
  {
    "benlubas/molten-nvim",
    lazy = false,
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_image_provider = require("config.notebooks").images_enabled() and "image.nvim" or "none"
    end,
  },
  {
    "GCBallesteros/jupytext.nvim",
    -- Must register BufReadCmd before the first notebook is opened.
    lazy = false,
    opts = { style = "markdown", output_extension = "md", force_ft = "markdown" },
  },
  {
    "quarto-dev/quarto-nvim",
    lazy = false,
    dependencies = { "jmbuhr/otter.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      lspFeatures = { languages = { "python" }, chunks = "all" },
      codeRunner = { enabled = true, default_method = "molten" },
    },
  },
  {
    "3rd/image.nvim",
    build = false, -- magick_cli uses the installed executable, without Lua rocks.
    lazy = false,
    cond = function() return require("config.notebooks").images_enabled() end,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      -- Notebook images are managed by Molten; avoid a second Markdown renderer.
      integrations = { markdown = { enabled = false }, neorg = { enabled = false } },
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = true,
      tmux_show_only_in_active_window = true,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({ "markdown", "markdown_inline", "python", "yaml" })
    end,
  },
}
