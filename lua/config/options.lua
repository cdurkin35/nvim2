local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false -- statusline shows the mode
opt.laststatus = 3 -- single global statusline
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.splitright = true
opt.splitbelow = true
opt.pumheight = 12
opt.winborder = "rounded"
opt.fillchars = { eob = " " }

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.shiftround = true
opt.virtualedit = "block"
opt.confirm = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
if vim.fn.executable("rg") == 1 then
    opt.grepprg = "rg --vimgrep --smart-case"
    opt.grepformat = "%f:%l:%c:%m"
end

-- Files
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
opt.timeoutlen = 400

-- Use the system clipboard (deferred: the clipboard provider can be slow to detect).
vim.schedule(function()
    opt.clipboard = "unnamedplus"
end)

-- Folding via treesitter, all folds open by default.
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""

opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess:append("cI")

-- Disable unused remote-plugin providers (faster startup, fewer health warnings).
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
