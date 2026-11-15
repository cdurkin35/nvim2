-- Colorful mini.statusline layout using the gruvbox palette:
--
--  NORMAL │  main +3 ~1 -2 │ E1 W2 │ path/file.c [+]        clangd │ c utf-8 unix │ 12:5 40%
--  (mode)   (git, orange/green/aqua/red)  (diagnostics)       (lsp)   (file info)   (mode)
--
-- Git info comes from gitsigns' buffer variables; diagnostics from vim.diagnostic.

local M = {}

local function icons()
    return vim.g.have_nerd_font ~= false
end

-- Define (or redefine after a colorscheme change) the statusline highlight groups.
local function set_highlights()
    local ok, gruvbox = pcall(require, "gruvbox")
    if not ok then
        return
    end
    local p = gruvbox.palette
    local bar = p.dark1 -- main bar background
    local block = p.dark2 -- slightly lighter blocks next to the mode
    local hl = function(name, spec)
        vim.api.nvim_set_hl(0, name, spec)
    end

    -- Mode blocks (also reused for the location block on the right)
    hl("MiniStatuslineModeNormal", { fg = p.dark0, bg = p.neutral_yellow, bold = true })
    hl("MiniStatuslineModeInsert", { fg = p.dark0, bg = p.bright_blue, bold = true })
    hl("MiniStatuslineModeVisual", { fg = p.dark0, bg = p.bright_orange, bold = true })
    hl("MiniStatuslineModeReplace", { fg = p.dark0, bg = p.bright_red, bold = true })
    hl("MiniStatuslineModeCommand", { fg = p.dark0, bg = p.bright_green, bold = true })
    hl("MiniStatuslineModeOther", { fg = p.dark0, bg = p.bright_aqua, bold = true })

    -- Bar sections
    hl("StatusLine", { fg = p.light2, bg = bar })
    hl("MiniStatuslineDevinfo", { fg = p.light2, bg = block })
    hl("MiniStatuslineFilename", { fg = p.light1, bg = bar, bold = true })
    hl("MiniStatuslineFileinfo", { fg = p.bright_aqua, bg = block })
    hl("MiniStatuslineInactive", { fg = p.gray, bg = p.dark0_soft })

    -- Accents
    hl("UserSlBranch", { fg = p.bright_orange, bg = block, bold = true })
    hl("UserSlAdded", { fg = p.bright_green, bg = block })
    hl("UserSlChanged", { fg = p.bright_aqua, bg = block })
    hl("UserSlRemoved", { fg = p.bright_red, bg = block })
    hl("UserSlError", { fg = p.bright_red, bg = bar, bold = true })
    hl("UserSlWarn", { fg = p.bright_yellow, bg = bar, bold = true })
    hl("UserSlInfo", { fg = p.bright_blue, bg = bar })
    hl("UserSlHint", { fg = p.bright_aqua, bg = bar })
    hl("UserSlModified", { fg = p.bright_red, bg = bar, bold = true })
    hl("UserSlLsp", { fg = p.bright_purple, bg = bar, bold = true })
end

-- Escape "%" so text from buffers/branches can't inject statusline items.
local function esc(s)
    return (s:gsub("%%", "%%%%"))
end

local function section_git()
    local head = vim.b.gitsigns_head
    if not head or head == "" then
        return ""
    end
    local parts = { "%#UserSlBranch# " .. (icons() and " " or "git:") .. esc(head) }
    local d = vim.b.gitsigns_status_dict or {}
    if (d.added or 0) > 0 then
        table.insert(parts, "%#UserSlAdded#+" .. d.added)
    end
    if (d.changed or 0) > 0 then
        table.insert(parts, "%#UserSlChanged#~" .. d.changed)
    end
    if (d.removed or 0) > 0 then
        table.insert(parts, "%#UserSlRemoved#-" .. d.removed)
    end
    return table.concat(parts, " ") .. " "
end

local function section_diagnostics()
    local counts = vim.diagnostic.count(0)
    local s = vim.diagnostic.severity
    local spec = {
        { s.ERROR, "E", "UserSlError" },
        { s.WARN, "W", "UserSlWarn" },
        { s.INFO, "I", "UserSlInfo" },
        { s.HINT, "H", "UserSlHint" },
    }
    local parts = {}
    for _, item in ipairs(spec) do
        local n = counts[item[1]]
        if n and n > 0 then
            table.insert(parts, "%#" .. item[3] .. "#" .. item[2] .. n)
        end
    end
    return #parts > 0 and (" " .. table.concat(parts, " ") .. " ") or ""
end

local function section_filename()
    local name = vim.fn.expand("%:~:.")
    if name == "" then
        name = "[No Name]"
    end
    if vim.o.columns < 100 then
        name = vim.fn.pathshorten(name)
    end
    local s = "%#MiniStatuslineFilename# " .. esc(name)
    if vim.bo.modified then
        s = s .. " %#UserSlModified#[+]"
    elseif vim.bo.readonly or not vim.bo.modifiable then
        s = s .. " %#UserSlModified#[RO]"
    end
    return s .. " "
end

local function section_lsp()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        table.insert(names, client.name)
    end
    if #names == 0 then
        return ""
    end
    return "%#UserSlLsp#" .. (icons() and " " or "") .. esc(table.concat(names, ",")) .. " "
end

local function section_fileinfo()
    local ft = vim.bo.filetype
    if ft == "" then
        return ""
    end
    local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
    local info = ft
    if vim.o.columns >= 120 then
        info = info .. "  " .. enc .. "  " .. vim.bo.fileformat
    end
    return "%#MiniStatuslineFileinfo# " .. esc(info) .. " "
end

function M.active()
    local MiniStatusline = require("mini.statusline")
    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
    local wide = vim.o.columns >= 80
    return table.concat({
        "%#" .. mode_hl .. "# " .. mode .. " ",
        wide and section_git() or "",
        "%#StatusLine#",
        section_diagnostics(),
        "%<",
        section_filename(),
        "%#StatusLine#%=",
        wide and section_lsp() or "",
        section_fileinfo(),
        "%#" .. mode_hl .. "# %l:%v %P ",
    })
end

function M.setup()
    set_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user_statusline_colors", { clear = true }),
        callback = set_highlights,
    })
    -- Redraw when git or diagnostic info changes
    local group = vim.api.nvim_create_augroup("user_statusline_redraw", { clear = true })
    local redraw = function()
        vim.cmd.redrawstatus()
    end
    vim.api.nvim_create_autocmd(
        "User",
        { group = group, pattern = "GitSignsUpdate", callback = redraw }
    )
    vim.api.nvim_create_autocmd(
        { "DiagnosticChanged", "LspAttach", "LspDetach" },
        { group = group, callback = redraw }
    )

    require("mini.statusline").setup({
        use_icons = icons(),
        content = { active = M.active },
    })
end

return M
