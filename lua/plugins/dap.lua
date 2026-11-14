-- Debugging: nvim-dap + dap-ui.
--   Host C/C++      -> codelldb (Mason)
--   Host Rust       -> rustaceanvim (`<leader>dr` debuggables), also uses codelldb
--   Python          -> debugpy (Mason) via nvim-dap-python
--   Embedded        -> GDB's native DAP (gdb >= 14) attached to any GDB server
--                      (OpenOCD, J-Link, pyOCD, `probe-rs gdb`, QEMU -s), or
--                      probe-rs's own DAP server (flash + debug + RTT).
-- Project-specific configs in .vscode/launch.json are picked up automatically.

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages"

local function first_executable(candidates)
    for _, exe in ipairs(candidates) do
        if vim.fn.executable(exe) == 1 then
            return exe
        end
    end
end

local function ask_elf()
    local path = vim.fn.input("ELF / executable: ", vim.fn.getcwd() .. "/", "file")
    return path ~= "" and path or require("dap").ABORT
end

local function ask(prompt, default)
    return function()
        local value = vim.fn.input(prompt, default or "")
        return value ~= "" and value or require("dap").ABORT
    end
end

-- Build a keymap callback that lazily calls require(mod).<path>().
local function call(mod, path)
    return function()
        local fn = require(mod)
        for part in path:gmatch("[^.]+") do
            fn = fn[part]
        end
        fn()
    end
end

local function setup_adapters(dap)
    -- codelldb (host C/C++)
    local codelldb = first_executable({ mason_bin .. "/codelldb", "codelldb" })
    if codelldb then
        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = { command = codelldb, args = { "--port", "${port}" } },
        }
    end

    -- GDB native DAP (embedded + host fallback). Prefer a multi-arch build.
    local gdb = first_executable({ "gdb-multiarch", "arm-none-eabi-gdb", "gdb" })
    if gdb then
        dap.adapters.gdb = {
            type = "executable",
            command = gdb,
            args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
        }
    end

    -- probe-rs DAP server
    if vim.fn.executable("probe-rs") == 1 then
        dap.adapters["probe-rs-debug"] = {
            type = "server",
            port = "${port}",
            executable = { command = "probe-rs", args = { "dap-server", "--port", "${port}" } },
        }

        -- Forward probe-rs RTT output and messages to the REPL.
        local id = "user_probe_rs"
        dap.listeners.before["event_probe-rs-rtt-channel-config"][id] = function(session, body)
            session:request("rttWindowOpened", { body.channelNumber, true })
        end
        dap.listeners.before["event_probe-rs-rtt-data"][id] = function(_, body)
            dap.repl.append(string.format("[RTT %d] %s", body.channelNumber, body.data))
        end
        dap.listeners.before["event_probe-rs-show-message"][id] = function(_, body)
            dap.repl.append(string.format("[probe-rs %s] %s", body.severity, body.message))
        end
    end
end

local function setup_configurations(dap)
    local embedded = {
        {
            name = "Embedded: attach to GDB server (OpenOCD/J-Link/pyOCD/QEMU)",
            type = "gdb",
            request = "attach",
            program = ask_elf,
            target = ask("GDB server (host:port): ", "localhost:3333"),
            cwd = "${workspaceFolder}",
        },
        {
            name = "Embedded: probe-rs flash & debug",
            type = "probe-rs-debug",
            request = "launch",
            cwd = "${workspaceFolder}",
            chip = ask("Chip (e.g. STM32F411CEUx, nRF52840_xxAA, RP2040): "),
            flashingConfig = { flashingEnabled = true, haltAfterReset = true },
            coreConfigs = {
                { coreIndex = 0, programBinary = ask_elf, rttEnabled = true },
            },
        },
        {
            name = "Embedded: probe-rs attach (no flash)",
            type = "probe-rs-debug",
            request = "attach",
            cwd = "${workspaceFolder}",
            chip = ask("Chip: "),
            coreConfigs = {
                { coreIndex = 0, programBinary = ask_elf, rttEnabled = true },
            },
        },
    }

    local host_c = {
        {
            name = "Host: launch (codelldb)",
            type = "codelldb",
            request = "launch",
            program = ask_elf,
            args = function()
                return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
        },
        {
            name = "Host: attach to process (codelldb)",
            type = "codelldb",
            request = "attach",
            pid = function()
                return require("dap.utils").pick_process()
            end,
        },
        {
            name = "Host: launch (gdb)",
            type = "gdb",
            request = "launch",
            program = ask_elf,
            cwd = "${workspaceFolder}",
            stopAtBeginningOfMainSubprogram = false,
        },
    }

    dap.configurations.c = vim.list_extend(vim.deepcopy(host_c), embedded)
    dap.configurations.cpp = dap.configurations.c
    dap.configurations.asm = embedded
    -- Host Rust debugging is provided by rustaceanvim (:RustLsp debuggables).
    dap.configurations.rust = vim.deepcopy(embedded)
end

return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "mfussenegger/nvim-dap-python",
        },
        keys = {
            { "<F5>", call("dap", "continue"), desc = "Debug: continue/start" },
            { "<F10>", call("dap", "step_over"), desc = "Debug: step over" },
            { "<F11>", call("dap", "step_into"), desc = "Debug: step into" },
            { "<F12>", call("dap", "step_out"), desc = "Debug: step out" },
            { "<leader>dc", call("dap", "continue"), desc = "Continue/start" },
            { "<leader>db", call("dap", "toggle_breakpoint"), desc = "Toggle breakpoint" },
            {
                "<leader>dB",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Condition: "))
                end,
                desc = "Conditional breakpoint",
            },
            { "<leader>dC", call("dap", "run_to_cursor"), desc = "Run to cursor" },
            { "<leader>dl", call("dap", "run_last"), desc = "Run last" },
            { "<leader>dp", call("dap", "pause"), desc = "Pause" },
            { "<leader>dt", call("dap", "terminate"), desc = "Terminate" },
            { "<leader>du", call("dapui", "toggle"), desc = "Toggle UI" },
            { "<leader>de", call("dapui", "eval"), mode = { "n", "x" }, desc = "Eval" },
            { "<leader>dR", call("dap", "repl.toggle"), desc = "Toggle REPL" },
        },
        config = function()
            local dap = require("dap")
            setup_adapters(dap)
            setup_configurations(dap)

            -- Python (debugpy installed by Mason into its own venv)
            local debugpy_python = mason_pkg .. "/debugpy/venv/bin/python"
            if vim.fn.executable(debugpy_python) == 1 then
                require("dap-python").setup(debugpy_python)
            end

            local dapui = require("dapui")
            dapui.setup()
            dap.listeners.after.event_initialized["dapui"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui"] = function()
                dapui.close()
            end

            local sign = vim.fn.sign_define
            sign("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
            sign("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
            sign("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo" })
            sign("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
            sign("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
        end,
    },
}
