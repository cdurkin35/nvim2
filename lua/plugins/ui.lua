return {
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            contrast = "", -- standard gruvbox dark (not "hard"/"soft")
            transparent_mode = true, -- let the terminal draw the background
            italic = { strings = false, comments = true, operators = false, folds = true },
        },
        config = function(_, opts)
            vim.o.background = "dark" -- must be set before loading for gruvbox dark
            require("gruvbox").setup(opts)
            vim.cmd.colorscheme("gruvbox")
        end,
    },

    {
        "echasnovski/mini.nvim",
        version = false,
        lazy = false,
        config = function()
            -- Icons (also mocks nvim-web-devicons for plugins that expect it)
            require("mini.icons").setup()
            MiniIcons.mock_nvim_web_devicons()

            require("mini.statusline").setup({ use_icons = vim.g.have_nerd_font ~= false })

            -- Editing helpers
            require("mini.pairs").setup()
            require("mini.surround").setup() -- sa / sd / sr
            require("mini.ai").setup({ n_lines = 500 }) -- better a/i textobjects

            -- File explorer (floating Miller columns, edit the listing like a buffer)
            require("mini.files").setup({ windows = { preview = true, width_preview = 50 } })
        end,
        keys = {
            {
                "<leader>e",
                function()
                    local path = vim.api.nvim_buf_get_name(0)
                    if path == "" or not vim.uv.fs_stat(path) then
                        path = vim.uv.cwd()
                    end
                    require("mini.files").open(path, true)
                end,
                desc = "File explorer (current file)",
            },
            {
                "<leader>E",
                function()
                    require("mini.files").open(vim.uv.cwd(), true)
                end,
                desc = "File explorer (cwd)",
            },
        },
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
            spec = {
                { "<leader>b", group = "buffer" },
                { "<leader>c", group = "code" },
                { "<leader>d", group = "debug" },
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>u", group = "toggle" },
                { "gr", group = "lsp" },
            },
        },
    },
}
