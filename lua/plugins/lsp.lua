return {
    -- Provides server definitions in its `lsp/` directory; config/lsp.lua enables them.
    -- Loaded eagerly so the definitions are on the runtimepath before vim.lsp.enable().
    { "neovim/nvim-lspconfig", lazy = false },

    {
        "mason-org/mason.nvim",
        lazy = false, -- puts mason/bin on PATH at startup so servers can be found
        opts = { ui = { border = "rounded" } },
        keys = { { "<leader>cM", "<cmd>Mason<CR>", desc = "Mason" } },
    },

    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        event = "VeryLazy",
        cmd = { "MasonToolsInstall", "MasonToolsInstallSync", "MasonToolsUpdate" },
        opts = {
            ensure_installed = {
                -- C / C++
                "clangd",
                "clang-format",
                "codelldb",
                "neocmakelsp",
                -- Python
                "basedpyright",
                "ruff",
                "debugpy",
                -- Lua (for editing this config)
                "lua-language-server",
                "stylua",
                -- Treesitter parser builds
                "tree-sitter-cli",
            },
            run_on_start = true,
            start_delay = 2000,
        },
    },
}
