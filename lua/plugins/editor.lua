-- Locate an fzf binary: system PATH first, then the copy built by the junegunn/fzf plugin.
local function fzf_bin()
    if vim.fn.executable("fzf") == 1 then
        return "fzf"
    end
    return vim.fn.stdpath("data") .. "/lazy/fzf/bin/fzf"
end

local function fzf(cmd, opts)
    return function()
        require("fzf-lua")[cmd](opts or {})
    end
end

return {
    -- Downloads a prebuilt fzf binary so no system install is needed.
    { "junegunn/fzf", build = "./install --bin", lazy = true },

    {
        "ibhagwan/fzf-lua",
        cmd = "FzfLua",
        dependencies = { "junegunn/fzf" },
        opts = function()
            return {
                "default-title",
                fzf_bin = fzf_bin(),
                winopts = { height = 0.85, width = 0.85, preview = { layout = "flex" } },
                files = {
                    -- Prefer fd/rg when available; fzf-lua falls back to `find` otherwise.
                    cwd_prompt = false,
                },
                grep = {
                    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
                },
            }
        end,
        config = function(_, opts)
            require("fzf-lua").setup(opts)
            require("fzf-lua").register_ui_select()
        end,
        init = function()
            -- Use fzf-lua for vim.ui.select (code actions, etc.) once it is loaded.
            vim.ui.select = function(...)
                require("fzf-lua")
                return vim.ui.select(...)
            end
        end,
        keys = {
            { "<leader><space>", fzf("files"), desc = "Find files" },
            { "<leader>ff", fzf("files"), desc = "Find files" },
            { "<leader>fg", fzf("live_grep"), desc = "Live grep" },
            { "<leader>fw", fzf("grep_cword"), desc = "Grep word under cursor" },
            { "<leader>fw", fzf("grep_visual"), mode = "x", desc = "Grep selection" },
            { "<leader>fb", fzf("buffers"), desc = "Buffers" },
            { "<leader>fr", fzf("oldfiles"), desc = "Recent files" },
            { "<leader>fh", fzf("helptags"), desc = "Help tags" },
            { "<leader>fk", fzf("keymaps"), desc = "Keymaps" },
            { "<leader>fd", fzf("diagnostics_document"), desc = "Diagnostics (buffer)" },
            { "<leader>fD", fzf("diagnostics_workspace"), desc = "Diagnostics (workspace)" },
            { "<leader>fs", fzf("lsp_document_symbols"), desc = "Symbols (buffer)" },
            { "<leader>fS", fzf("lsp_live_workspace_symbols"), desc = "Symbols (workspace)" },
            { "<leader>fR", fzf("resume"), desc = "Resume last picker" },
            { "<leader>f/", fzf("blines"), desc = "Search in buffer" },
            { "<leader>gs", fzf("git_status"), desc = "Git status" },
            { "<leader>gc", fzf("git_commits"), desc = "Git commits" },
            { "gR", fzf("lsp_references"), desc = "References (picker)" },
        },
    },

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            on_attach = function(buf)
                local gs = require("gitsigns")
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
                end
                map("n", "]h", function()
                    gs.nav_hunk("next")
                end, "Next hunk")
                map("n", "[h", function()
                    gs.nav_hunk("prev")
                end, "Previous hunk")
                map({ "n", "x" }, "<leader>gh", gs.stage_hunk, "Stage/unstage hunk")
                map({ "n", "x" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
                map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
                map("n", "<leader>gb", gs.blame_line, "Blame line")
                map("n", "<leader>gB", gs.blame, "Blame buffer")
                map("n", "<leader>gd", gs.diffthis, "Diff against index")
            end,
        },
    },
}
