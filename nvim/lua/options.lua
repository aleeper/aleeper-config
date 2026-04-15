local opt = vim.opt

-- Indentation
opt.expandtab   = true   -- spaces, not tabs
opt.tabstop     = 2
opt.shiftwidth  = 2
opt.smartindent = true

-- Search
opt.ignorecase = true    -- case-insensitive by default
opt.smartcase  = true    -- ...unless pattern has uppercase
opt.incsearch  = true
opt.hlsearch   = false

-- UI
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"  -- always show gutter (prevents layout shift)
opt.ruler          = true
opt.cursorline     = true
opt.wrap           = false
opt.scrolloff      = 8
opt.sidescrolloff  = 8

-- Files / undo
opt.undofile = true    -- persistent undo across sessions
opt.swapfile = false
opt.backup   = false

-- Behavior
opt.mouse       = "a"
opt.clipboard   = "unnamedplus"  -- use system clipboard
opt.splitbelow  = true
opt.splitright  = true
opt.updatetime  = 250            -- faster completion/gitsigns refresh
opt.timeoutlen  = 300

-- Restore cursor position on file open (from old vimrc)
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Strip trailing whitespace on save (from old vimrc)
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Real tabs for Makefiles (from old vimrc)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function() vim.opt_local.expandtab = false end,
})
