vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Window navigation (Ctrl+hjkl) — normal mode
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Clear search highlights
map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear highlights" })

-- Buffer navigation
map("n", "<S-l>", ":bnext<CR>",     { desc = "Next buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Prev buffer" })

-- Stay in indent mode when indenting in visual
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>",  { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>",   { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>",     { desc = "Buffers" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>",    { desc = "Recent files" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",   { desc = "Help tags" })

-- LSP (also set per-buffer in lsp.lua on_attach)
map("n", "gd",         vim.lsp.buf.definition,                          { desc = "Go to definition" })
map("n", "gr",         "<cmd>Telescope lsp_references<cr>",             { desc = "References" })
map("n", "K",          vim.lsp.buf.hover,                               { desc = "Hover docs" })
map("n", "<leader>rn", vim.lsp.buf.rename,                              { desc = "Rename" })
map("n", "<leader>ca", vim.lsp.buf.code_action,                         { desc = "Code action" })
map("n", "[d",         vim.diagnostic.goto_prev,                        { desc = "Prev diagnostic" })
map("n", "]d",         vim.diagnostic.goto_next,                        { desc = "Next diagnostic" })
map("n", "<leader>e",  vim.diagnostic.open_float,                       { desc = "Diagnostic float" })
