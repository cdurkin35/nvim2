return {
    {
        -- Manages rust-analyzer (from rustup / PATH) and codelldb debugging for Rust.
        -- Do NOT also enable rust_analyzer via vim.lsp.enable().
        "mrcjkb/rustaceanvim",
        version = "^9",
        lazy = false, -- the plugin lazy-loads itself on the rust filetype
        init = function()
            vim.g.rustaceanvim = {
                server = {
                    on_attach = function(_, buf)
                        local function map(lhs, rhs, desc)
                            vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
                        end
                        map("<leader>ca", function()
                            vim.cmd.RustLsp("codeAction")
                        end, "Code action (Rust)")
                        map("<leader>cR", function()
                            vim.cmd.RustLsp("runnables")
                        end, "Rust runnables")
                        map("<leader>ce", function()
                            vim.cmd.RustLsp("explainError")
                        end, "Explain error")
                        map("<leader>cx", function()
                            vim.cmd.RustLsp("expandMacro")
                        end, "Expand macro")
                        map("<leader>dr", function()
                            vim.cmd.RustLsp("debuggables")
                        end, "Rust debuggables")
                    end,
                    default_settings = {
                        ["rust-analyzer"] = {
                            cargo = { allFeatures = false },
                            -- Don't check tests/benches for every target: important for
                            -- no_std crates where the host test harness doesn't build.
                            check = { command = "clippy", allTargets = false },
                            procMacro = { enable = true },
                        },
                    },
                },
                -- Per-project overrides (e.g. cargo.target = "thumbv7em-none-eabihf") are
                -- read from rust-analyzer.toml or .vscode/settings.json in the project.
            }
        end,
    },

    {
        "saecki/crates.nvim",
        event = "BufRead Cargo.toml",
        opts = { lsp = { enabled = true, actions = true, completion = true, hover = true } },
    },
}
