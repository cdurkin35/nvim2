# My personal Neovim Configuration

A small, fast Neovim config for C, C++, Rust and Python, including embedded targets.
It needs **Neovim 0.12+** and uses native LSP (`vim.lsp.config` / `vim.lsp.enable`),
[lazy.nvim](https://github.com/folke/lazy.nvim) for plugins, and
[Mason](https://github.com/mason-org/mason.nvim) for language servers and tools, so very
little has to be installed on the machine itself.

## Requirements

| Needed | Why |
| --- | --- |
| `nvim` ≥ 0.12 | |
| `git`, `curl`, `unzip`, `tar` | lazy.nvim + Mason downloads |
| C compiler (`gcc`/`clang`) | building treesitter parsers |
| `rustup` + `rustup component add rust-analyzer rust-src` | Rust LSP (matches your toolchain) |
| `python3` with `venv` | Mason installs `debugpy` into a venv |

Optional: `rg` (faster grep), `fd` (faster file finding), a Nerd Font (icons),
`gdb-multiarch` / `arm-none-eabi-gdb`, `probe-rs`, `openocd` for embedded debugging.

Everything else installs itself on first start: plugins, an `fzf` binary, clangd,
clang-format, codelldb, basedpyright, ruff, debugpy, lua-language-server, stylua,
neocmakelsp and the `tree-sitter` CLI and parsers.

## Install

```sh
git clone <this repo> ~/.config/nvim
nvim   # first start installs plugins; Mason tools and parsers install in the background
```

To install everything headlessly (e.g. on a new machine or in CI):

```sh
nvim --headless "+Lazy! restore" +qa
nvim --headless "+MasonToolsInstallSync" +qa
```

Plugin versions are pinned in `lazy-lock.json`. `:Lazy update` updates them, and
`:Lazy restore` goes back to the locked versions.

## Layout

```
init.lua                 entry point
lua/config/              options, keymaps, autocmds, lazy bootstrap, LSP setup
lua/plugins/             one file per area (ui, editor, treesitter, lsp, completion,
                         format, rust, dap)
after/lsp/               per-server overrides merged over nvim-lspconfig's defaults
clang-format/            fallback .clang-format used when a project has none
```

### Plugins (~20)

gruvbox (dark, transparent background) · mini.nvim (statusline, icons, files, pairs, surround, ai) · which-key ·
fzf-lua (+ fzf) · gitsigns · nvim-treesitter · nvim-lspconfig · mason +
mason-tool-installer · blink.cmp + friendly-snippets · lazydev · conform ·
rustaceanvim · crates.nvim · nvim-dap + dap-ui + nio + dap-python

## Keymaps

Leader is `<Space>`. Press it and wait for which-key to list the options, or press
`<leader>?` for a full cheatsheet of every mapping, grouped by category (`q` closes it).

| Keys | Action |
| --- | --- |
| `<leader>?` | Keymap cheatsheet |
| `<leader><space>` / `<leader>ff` | Find files |
| `<leader>fg` / `<leader>fw` | Live grep / grep word |
| `<leader>fb` `fr` `fh` `fk` | Buffers, recent, help, keymaps |
| `<leader>fs` / `fS` | Document / workspace symbols |
| `<leader>fd` / `fD` | Diagnostics |
| `<leader>e` / `<leader>E` | File explorer (current file / cwd) |
| `gd` `gD` `grr` `gri` `grn` `gra` `K` | LSP: definition, declaration, refs, impl, rename, action, hover |
| `<leader>ca` `cr` `cf` | Code action, rename, format |
| `<leader>ch` | Switch source/header (clangd) |
| `<leader>cm` | `:make`, errors go to quickfix |
| `<leader>cR` `ce` `cx` | Rust: runnables, explain error, expand macro |
| `[d` `]d` / `<leader>cd` | Prev/next diagnostic, line diagnostics |
| `]h` `[h` `<leader>gh` `gr` `gp` `gb` | Git hunks: nav, stage, reset, preview, blame |
| `<F5>` `<F10>` `<F11>` `<F12>` | Debug: continue, over, into, out |
| `<leader>db` `dB` `dC` `du` `de` `dt` | Breakpoint, conditional, run to cursor, UI, eval, terminate |
| `<leader>dr` | Rust debuggables |
| `<leader>uf` `uh` `ud` `uw` | Toggle format-on-save, inlay hints, diagnostics, wrap |
| `<leader>t` | Terminal split (`<Esc><Esc>` leaves terminal mode) |
| `gc` / `gcc` | Comment (built in) |
| `sa` `sd` `sr` | Add / delete / replace surrounding |

## Language notes

### C / C++ (including embedded)

clangd needs a `compile_commands.json` at the project root (or in `build/`):

- CMake: `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
- Make or other build systems: `bear -- make`

clangd starts with `--query-driver` set for `*-gcc`/`*-g++`/`*-clang`, so cross compilers
such as `arm-none-eabi-gcc` report their own system headers and target macros. If GCC-only
flags cause errors, add a `.clangd` file to the project:

```yaml
CompileFlags:
  Remove: [-mthumb-interwork, -fno-tree-loop-distribute-patterns, -fstack-usage]
  Add: [-Wno-unknown-warning-option]
```

Formatting uses the project's `.clang-format` when it has one. Otherwise it falls back to
`clang-format/.clang-format` in this repo.

### Rust (including embedded)

rustaceanvim runs rust-analyzer and wires up codelldb for host debugging. For `no_std`
targets, set the target per project in `rust-analyzer.toml` or `.vscode/settings.json`:

```toml
# rust-analyzer.toml
[cargo]
target = "thumbv7em-none-eabihf"
```

### Python

basedpyright handles types and navigation, and ruff handles linting, formatting and import
sorting. Activate the project's virtualenv before starting `nvim` (or set `venvPath`/`venv`
under `[tool.basedpyright]` in `pyproject.toml`) so imports resolve.

## Debugging

`<F5>` lists the configurations for the current filetype:

- **Host: launch / attach (codelldb)**, **Host: launch (gdb)**: native C/C++ programs.
- **Embedded: attach to GDB server**: uses GDB's built-in DAP (`gdb-multiarch -i dap`,
  gdb ≥ 14). Start a GDB server first, then give it the ELF and `host:port`:
  - OpenOCD: `openocd -f interface/stlink.cfg -f target/stm32f4x.cfg` (port 3333)
  - J-Link: `JLinkGDBServer -device <chip> -if SWD` (port 2331)
  - probe-rs: `probe-rs gdb --chip <chip>` (port 1337)
  - QEMU: `qemu-system-arm ... -s -S` (port 1234)
- **Embedded: probe-rs flash & debug / attach**: uses `probe-rs dap-server`. It flashes,
  halts and streams RTT output to the DAP REPL.
- **Python**: debugpy configs from nvim-dap-python.
- **Rust host**: `<leader>dr` (rustaceanvim debuggables).

A project's `.vscode/launch.json` is loaded automatically, so team-shared configs work.
