-- nvim-treesitter `main` branch: it only installs parsers/queries; highlighting, folds and
-- indent are started with Neovim's built-in vim.treesitter APIs below.
-- Parser compilation needs a C compiler and the `tree-sitter` CLI (installed by Mason).
local parsers = {
    "asm",
    "bash",
    "c",
    "cmake",
    "cpp",
    "devicetree",
    "diff",
    "gitcommit",
    "json",
    "kconfig",
    "linkerscript",
    "lua",
    "luadoc",
    "make",
    "markdown",
    "markdown_inline",
    "ninja",
    "python",
    "query",
    "rust",
    "toml",
    "vim",
    "vimdoc",
    "yaml",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false, -- main branch does not support lazy-loading
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup()

            -- Install missing parsers in the background (no-op when all are present).
            local installed = ts.get_installed()
            local missing = vim.tbl_filter(function(p)
                return not vim.tbl_contains(installed, p)
            end, parsers)
            if #missing > 0 then
                local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
                if not vim.env.PATH:find(mason_bin, 1, true) then
                    vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
                end
                if vim.fn.executable("tree-sitter") == 1 then
                    ts.install(missing)
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
                callback = function(args)
                    if not pcall(vim.treesitter.start, args.buf) then
                        return
                    end
                    -- Treesitter indentation (skip Python; its indent queries are weaker
                    -- than the built-in indent script).
                    local ft = vim.bo[args.buf].filetype
                    if ft ~= "python" then
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
