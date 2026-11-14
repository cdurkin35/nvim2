local group = vim.api.nvim_create_augroup("user_config", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight yanked text
autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

-- Restore cursor position when reopening a file
autocmd("BufReadPost", {
    group = group,
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local lines = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= lines and vim.bo[args.buf].filetype ~= "gitcommit" then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Equalize splits when the terminal is resized
autocmd("VimResized", {
    group = group,
    command = "tabdo wincmd =",
})

-- Close helper windows with q
autocmd("FileType", {
    group = group,
    pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "dap-float" },
    callback = function(args)
        vim.bo[args.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true })
    end,
})

-- Per-filetype indentation
autocmd("FileType", {
    group = group,
    pattern = { "lua", "json", "jsonc", "yaml", "toml", "markdown", "cmake" },
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
    end,
})
autocmd("FileType", {
    group = group,
    pattern = { "make" },
    callback = function()
        vim.opt_local.expandtab = false
    end,
})
autocmd("FileType", {
    group = group,
    pattern = { "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- Pick a sensible :make program per project
autocmd("FileType", {
    group = group,
    pattern = { "rust" },
    callback = function()
        vim.opt_local.makeprg = "cargo build"
    end,
})

-- Treat common embedded file extensions correctly
vim.filetype.add({
    extension = {
        ld = "ld",
        s = "asm",
        S = "asm",
        dts = "dts",
        dtsi = "dts",
        overlay = "dts",
    },
    filename = {
        ["memory.x"] = "ld",
    },
})
