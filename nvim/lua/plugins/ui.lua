-- UI: colorscheme (github-dark to match tmux), status line, icons
return {
  -- github-nvim-theme: matches your tmux github-dark theme
  {
    "projekt0n/github-nvim-theme",
    priority = 1000,
    config   = function()
      require("github-theme").setup({
        options = { dim_inactive = true },
      })
      vim.cmd("colorscheme github_dark")
    end,
  },

  -- lualine: status line with git branch, diagnostics, LSP info
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme                = "auto",
          component_separators = "|",
          section_separators   = "",
        },
        sections = {
          lualine_c = { { "filename", path = 1 } },   -- show relative path
          lualine_x = { "diagnostics", "encoding", "filetype" },
        },
      })
    end,
  },
}
