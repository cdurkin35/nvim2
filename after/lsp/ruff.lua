return {
    on_attach = function(client)
        -- Let basedpyright provide hover.
        client.server_capabilities.hoverProvider = false
    end,
}
