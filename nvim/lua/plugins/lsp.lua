-- LSP servers, completion, and auto-formatting
-- Uses nvim 0.11+ native API (vim.lsp.config / vim.lsp.enable).
-- nvim-lspconfig is kept as a server config registry but its setup() API is not used.
return {
  -- Mason: installs LSP servers, formatters, linters
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- mason-lspconfig: ensures servers are installed via Mason
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright", "lua_ls", "bashls" },
        automatic_installation = true,
      })
    end,
  },

  -- nvim-lspconfig: auto-registers server defaults (cmd, filetypes, root_markers)
  -- We use vim.lsp.config/enable (nvim 0.11 API) instead of lspconfig.xxx.setup()
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }
        vim.keymap.set("n", "gd",         vim.lsp.buf.definition,              opts)
        vim.keymap.set("n", "gr",         "<cmd>Telescope lsp_references<cr>", opts)
        vim.keymap.set("n", "K",          vim.lsp.buf.hover,                   opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,                  opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,             opts)
      end

      -- Global defaults for all servers
      vim.lsp.config("*", {
        capabilities = capabilities,
        on_attach    = on_attach,
      })

      -- Server-specific overrides
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace   = { checkThirdParty = false },
            telemetry   = { enable = false },
          },
        },
      })

      -- Enable servers (their defaults were registered by nvim-lspconfig on load)
      vim.lsp.enable({ "clangd", "pyright", "lua_ls", "bashls" })
    end,
  },

  -- nvim-cmp: completion engine
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- conform: auto-format on save
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
        formatters_by_ft = {
          python = { "black", "ruff" },
          cpp    = { "clang_format" },
          c      = { "clang_format" },
          lua    = { "stylua" },
          sh     = { "shfmt" },
        },
      })
    end,
  },
}
