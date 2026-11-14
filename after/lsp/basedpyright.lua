-- Type checking/navigation from basedpyright; linting/formatting is left to ruff.
return {
    settings = {
        basedpyright = {
            disableOrganizeImports = true, -- ruff handles imports
            analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
            },
        },
    },
}
