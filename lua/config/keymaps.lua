local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map({ "n", "i", "x" }, "<C-s>", "<cmd>write<CR><Esc>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qall<CR>", { desc = "Quit all" })

-- Window navigation / resizing
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

-- Buffers
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bo", "<cmd>%bdelete|edit#|bdelete#<CR>", { desc = "Delete other buffers" })

-- Keep selection when indenting; move lines
map("x", "<", "<gv")
map("x", ">", ">gv")
map("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Paste over selection without clobbering the register
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })

-- Diagnostics ([d / ]d are Neovim defaults)
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Quickfix
map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })

-- Build: run :make (uses makeprg, e.g. cargo/make) and open quickfix on errors
map("n", "<leader>cm", "<cmd>make! | cwindow<CR>", { desc = "Run :make" })

-- Terminal
map("n", "<leader>t", "<cmd>botright split | resize 15 | terminal<CR>", { desc = "Terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggles
map("n", "<leader>uw", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })
map("n", "<leader>ur", function()
    vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers" })
map("n", "<leader>ud", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
