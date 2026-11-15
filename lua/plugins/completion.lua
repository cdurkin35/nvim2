return {
    {
        "saghen/blink.cmp",
        version = "1.*", -- tagged releases ship a prebuilt fuzzy matcher (no Rust build)
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = {
                preset = "default", -- <C-y> accept, <C-n>/<C-p> select, <C-space> open
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
                ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
            },
            appearance = { nerd_font_variant = "mono" },
            completion = {
                list = { selection = { preselect = false, auto_insert = true } },
                documentation = { auto_show = true, auto_show_delay_ms = 300 },
                menu = { draw = { treesitter = { "lsp" } } },
            },
            signature = { enabled = true },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
                per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
    },

    -- Neovim API completion/types when editing this config
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
    },
}
