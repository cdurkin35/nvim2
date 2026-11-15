-- Native LSP setup (Neovim 0.11+).
-- Server definitions come from nvim-lspconfig's `lsp/` directory; local overrides live in
-- this config's `lsp/` directory and are merged on top. Rust is handled by rustaceanvim.

vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
    float = { border = "rounded", source = true },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
})

-- Capabilities shared by every server (blink.cmp adds completion capabilities).
vim.lsp.config("*", {
    root_markers = { ".git" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
    callback = function(args)
        local buf = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, desc = desc })
        end

        -- Defaults already provided by Neovim: K, grn, gra, grr, gri, grt, gO, <C-s> (insert)
        map("gd", vim.lsp.buf.definition, "Goto definition")
        map("gD", vim.lsp.buf.declaration, "Goto declaration")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
        map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")

        if client and client.name == "clangd" then
            map("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch source/header")
        end

        if client and client:supports_method("textDocument/inlayHint") then
            map("<leader>uh", function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = buf })
            end, "Toggle inlay hints")
        end

        -- Highlight references of the symbol under the cursor
        if client and client:supports_method("textDocument/documentHighlight") then
            local hl = vim.api.nvim_create_augroup("user_lsp_highlight_" .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = hl,
                buffer = buf,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
                group = hl,
                buffer = buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})

vim.lsp.enable({
    "clangd",
    "basedpyright",
    "ruff",
    "lua_ls",
    "neocmake",
})
