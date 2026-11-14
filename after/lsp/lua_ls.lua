return {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            hint = { enable = true },
        },
    },
}
