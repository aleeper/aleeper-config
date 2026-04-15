-- Editor enhancements: treesitter, telescope, git signs, comments, which-key
return {
  -- Treesitter: better syntax highlighting and indent
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
    opts = {
      ensure_installed = {
        "c", "cpp", "python", "lua", "bash",
        "yaml", "json", "toml", "markdown", "cmake",
      },
      auto_install = true,
      highlight    = { enable = true },
      indent       = { enable = true },
    },
  },

  -- Telescope: fuzzy finder (files, grep, LSP, etc.)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      local actions   = require("telescope.actions")

      telescope.setup({
        defaults = {
          path_display = { "smart" },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- Gitsigns: inline git blame and hunk navigation
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local gs   = package.loaded.gitsigns
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "]h",         gs.next_hunk,   opts)
          vim.keymap.set("n", "[h",         gs.prev_hunk,   opts)
          vim.keymap.set("n", "<leader>hs", gs.stage_hunk,  opts)
          vim.keymap.set("n", "<leader>hr", gs.reset_hunk,  opts)
          vim.keymap.set("n", "<leader>hb", gs.blame_line,  opts)
          vim.keymap.set("n", "<leader>hd", gs.diffthis,    opts)
        end,
      })
    end,
  },

  -- mini.comment: gcc / gc to comment lines/selections
  {
    "echasnovski/mini.comment",
    version = false,
    config  = function() require("mini.comment").setup() end,
  },

  -- which-key: shows available keybindings as you type
  {
    "folke/which-key.nvim",
    event  = "VeryLazy",
    config = function() require("which-key").setup() end,
  },
}
