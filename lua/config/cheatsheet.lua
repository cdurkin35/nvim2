-- NvChad-style keymap cheatsheet: a floating window listing every mapping that has a
-- description, grouped into categories and laid out in columns. Opened with <leader>?.
-- Built from the live keymap tables, so it stays in sync with the config automatically
-- (including lazy-loaded plugin keys and the current buffer's LSP maps).

local M = {}

local MODES = { "n", "x", "i", "t" }
local COL_WIDTH = 52

-- Friendlier names for Neovim's built-in LSP maps (their desc is the function name).
local DESC_OVERRIDES = {
    ["vim.lsp.buf.rename()"] = "Rename symbol",
    ["vim.lsp.buf.code_action()"] = "Code action",
    ["vim.lsp.buf.references()"] = "References",
    ["vim.lsp.buf.implementation()"] = "Implementation",
    ["vim.lsp.buf.type_definition()"] = "Type definition",
    ["vim.lsp.buf.document_symbol()"] = "Document symbols",
    ["vim.lsp.buf.signature_help()"] = "Signature help",
    ["vim.lsp.codelens.run()"] = "Run codelens",
    ["vim.lsp.buf.hover()"] = "Hover documentation",
}

-- Skip noise: built-in ex-command shortcuts ("[b" -> ":bprevious"), auto-pair insert
-- maps, and mini.surround's prev/next variants (sdl, sdn, ...).
local function is_noise(lhs, desc, mode)
    if desc:match("^:") then
        return true
    end
    if mode == "i" and (desc:match("pair") or desc:match("^MiniPairs")) then
        return true
    end
    if lhs:match("^s[adfFhr][ln]$") then
        return true
    end
    return false
end
local GAP = 2

-- Ordered categories, matched against the normalized lhs. First match wins.
local CATEGORIES = {
    { name = "Find", match = "^<leader>f" },
    { name = "Code / LSP", match = "^<leader>c" },
    { name = "LSP (g prefix)", match = "^g" },
    { name = "Debug", match = { "^<leader>d", "^<F%d+>" } },
    { name = "Git", match = "^<leader>g" },
    { name = "Buffers", match = { "^<leader>b", "^[HL]$" } },
    { name = "Toggles", match = "^<leader>u" },
    { name = "Navigation", match = { "^%[", "^%]" } },
    { name = "Text objects", match = "^[ai][ln]?$" },
    { name = "Surround", match = "^s[adfFhrn]" },
    {
        name = "Windows",
        match = {
            "^<C%-[HJKL]>$",
            "^<C%-Up>",
            "^<C%-Down>",
            "^<C%-Left>",
            "^<C%-Right>",
            "^<C%-W>",
        },
    },
    { name = "Leader", match = "^<leader>" },
    { name = "General", match = ".*" },
}

local function normalize(lhs)
    -- lhs may hold raw bytes or "<C-x>" notation; round-trip to get one canonical form.
    local keys = vim.fn.keytrans(vim.keycode(lhs))
    keys = keys:gsub("<NL>", "<C-J>") -- <C-j> and <NL> are the same byte
    local leader = vim.fn.keytrans(vim.g.mapleader or "\\")
    if keys:sub(1, #leader) == leader then
        keys = "<leader>" .. keys:sub(#leader + 1)
    end
    return keys
end

local function category_of(lhs)
    for i, cat in ipairs(CATEGORIES) do
        local patterns = type(cat.match) == "table" and cat.match or { cat.match }
        for _, pat in ipairs(patterns) do
            if lhs:match(pat) then
                return i
            end
        end
    end
    return #CATEGORIES
end

-- Collect global + buffer-local maps, merging identical lhs/desc pairs across modes.
local function collect(buf)
    local by_key = {}
    local function add(map, mode)
        local desc = map.desc
        if not desc or desc == "" or map.lhs:find("<Plug>", 1, true) then
            return
        end
        local lhs = normalize(map.lhs)
        desc = DESC_OVERRIDES[desc] or desc
        if desc:match("^vim%.snippet%.jump") then
            desc = "Snippet jump / completion"
        end
        if is_noise(lhs, desc, mode) then
            return
        end
        local id = lhs .. "\0" .. desc
        local entry = by_key[id]
        if entry then
            if not vim.tbl_contains(entry.modes, mode) then
                table.insert(entry.modes, mode)
            end
        else
            by_key[id] = { lhs = lhs, desc = desc, modes = { mode } }
        end
    end
    for _, mode in ipairs(MODES) do
        for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
            add(map, mode)
        end
        for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
            add(map, mode)
        end
    end

    local groups = {}
    for _, entry in pairs(by_key) do
        local idx = category_of(entry.lhs)
        groups[idx] = groups[idx] or {}
        table.insert(groups[idx], entry)
    end
    local result = {}
    for i, cat in ipairs(CATEGORIES) do
        local items = groups[i]
        if items then
            table.sort(items, function(a, b)
                return a.lhs:lower() < b.lhs:lower()
            end)
            table.insert(result, { name = cat.name, items = items })
        end
    end
    return result
end

local function truncate(s, width)
    if vim.fn.strdisplaywidth(s) <= width then
        return s
    end
    return vim.fn.strcharpart(s, 0, width - 1) .. "…"
end

local function pad(s, width)
    return s .. string.rep(" ", math.max(0, width - vim.fn.strdisplaywidth(s)))
end

-- Turn one group into rows of { text, highlight spans }.
local function render_group(group)
    local rows = { { text = group.name, hl = { { 0, #group.name, "Title" } } } }
    table.insert(rows, { text = string.rep("─", COL_WIDTH), hl = { { 0, -1, "FloatBorder" } } })
    local key_width = 0
    for _, item in ipairs(group.items) do
        key_width = math.max(key_width, vim.fn.strdisplaywidth(item.lhs))
    end
    key_width = math.min(key_width, 22)
    for _, item in ipairs(group.items) do
        local mode = ""
        if not (#item.modes == 1 and item.modes[1] == "n") then
            mode = " [" .. table.concat(item.modes, "") .. "]"
        end
        local key = pad(truncate(item.lhs, key_width), key_width)
        local desc = truncate(item.desc, COL_WIDTH - key_width - 2 - #mode)
        local text = key .. "  " .. desc .. mode
        local hl = { { 0, #key, "Special" } }
        if mode ~= "" then
            table.insert(hl, { #text - #mode, #text, "Comment" })
        end
        table.insert(rows, { text = text, hl = hl })
    end
    table.insert(rows, { text = "", hl = {} })
    return rows
end

-- Pack groups into N columns (each group goes to the currently shortest column).
local function layout(groups, ncols)
    local cols = {}
    for i = 1, ncols do
        cols[i] = {}
    end
    for _, group in ipairs(groups) do
        local shortest = 1
        for i = 2, ncols do
            if #cols[i] < #cols[shortest] then
                shortest = i
            end
        end
        vim.list_extend(cols[shortest], render_group(group))
    end

    local height = 0
    for _, col in ipairs(cols) do
        height = math.max(height, #col)
    end

    local lines, marks = {}, {}
    for row = 1, height do
        local parts, offset = {}, 0
        for c = 1, ncols do
            local cell = cols[c][row] or { text = "", hl = {} }
            local text = c < ncols and pad(cell.text, COL_WIDTH + GAP) or cell.text
            for _, h in ipairs(cell.hl) do
                local stop = h[2] == -1 and #cell.text or h[2]
                table.insert(marks, { row - 1, offset + h[1], offset + stop, h[3] })
            end
            table.insert(parts, text)
            offset = offset + #text
        end
        lines[row] = (table.concat(parts)):gsub("%s+$", "")
    end
    return lines, marks
end

function M.open()
    local groups = collect(vim.api.nvim_get_current_buf())

    local max_w = math.floor(vim.o.columns * 0.92)
    local ncols = math.max(1, math.min(4, math.floor((max_w - 2) / (COL_WIDTH + GAP))))
    local lines, marks = layout(groups, ncols)

    local width = math.min(max_w, ncols * (COL_WIDTH + GAP))
    local height = math.min(#lines, math.floor(vim.o.lines * 0.85))

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local ns = vim.api.nvim_create_namespace("user_cheatsheet")
    for _, m in ipairs(marks) do
        pcall(
            vim.api.nvim_buf_set_extmark,
            buf,
            ns,
            m[1],
            m[2],
            { end_col = m[3], hl_group = m[4] }
        )
    end
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "cheatsheet"

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Cheatsheet ",
        title_pos = "center",
        footer = " q / <Esc> close · / search · [x]=visual [i]=insert [t]=terminal ",
        footer_pos = "center",
    })
    vim.wo[win].wrap = false
    vim.wo[win].cursorline = false

    for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
    end
end

return M
