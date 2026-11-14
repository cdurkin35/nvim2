-- Fallback clang-format style shipped with this config, used when a project has no
-- .clang-format / _clang-format of its own.
local fallback_clang_format = vim.fn.stdpath("config") .. "/clang-format/.clang-format"

vim.g.format_on_save = true

return {
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = "ConformInfo",
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = { "n", "x" },
                desc = "Format buffer/selection",
            },
            {
                "<leader>uf",
                function()
                    vim.g.format_on_save = not vim.g.format_on_save
                    vim.notify("Format on save: " .. (vim.g.format_on_save and "on" or "off"))
                end,
                desc = "Toggle format on save",
            },
        },
        opts = {
            formatters_by_ft = {
                c = { "clang_format" },
                cpp = { "clang_format" },
                rust = { "rustfmt" },
                python = { "ruff_organize_imports", "ruff_format" },
                lua = { "stylua" },
                cmake = { lsp_format = "prefer" },
            },
            formatters = {
                clang_format = {
                    prepend_args = function(_, ctx)
                        local found = vim.fs.find({ ".clang-format", "_clang-format" }, {
                            path = ctx.dirname,
                            upward = true,
                        })[1]
                        if found then
                            return { "--style=file" }
                        end
                        return { "--style=file:" .. fallback_clang_format }
                    end,
                },
            },
            format_on_save = function()
                if not vim.g.format_on_save then
                    return nil
                end
                return { timeout_ms = 1000, lsp_format = "fallback" }
            end,
        },
    },
}
