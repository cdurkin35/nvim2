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
snippets/                personal VSCode-format snippets (see Snippets below)
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

## Snippets

[friendly-snippets](https://github.com/rafamadriz/friendly-snippets) provides the common
language snippets (`for`, `if`, `main`, `struct`, `fn`, `def`, ...). The `snippets/`
directory adds personal ones focused on embedded and project boilerplate. Type the prefix
and pick it from the completion menu, then `<Tab>`/`<S-Tab>` jumps between fields.

Snippets are VSCode-format JSON. Edit them in `snippets/*.json`, map files to filetypes in
`snippets/package.json`, and restart Neovim to reload them.

<details><summary><b>All filetypes</b> (4)</summary>

| Prefix | Description |
| --- | --- |
| `todo` | TODO comment |
| `fixme` | FIXME comment |
| `note` | NOTE comment |
| `hack` | HACK comment |

</details>

<details><summary><b>C and C++</b> (26)</summary>

| Prefix | Description |
| --- | --- |
| `hdr` | Header with include guard and extern "C" wrapper |
| `externc` | extern "C" guard block |
| `fhdr` | Doxygen file header |
| `fdoc` | Doxygen function comment |
| `banner` | Section separator comment |
| `reg32` | Memory-mapped 32-bit register macro |
| `bitm` | BIT(n) macro |
| `bitset` | Set a bit |
| `bitclr` | Clear a bit |
| `bittog` | Toggle a bit |
| `bitchk` | Test a bit |
| `bitfld` | Read-modify-write a bit field |
| `waitflag` | Busy-wait on a status flag with timeout |
| `isr` | Interrupt service routine |
| `critical` | Save PRIMASK, disable IRQs, restore |
| `packed` | Packed typedef struct |
| `section` | Place symbol in a linker section |
| `weak` | Weak symbol attribute |
| `aligned` | Alignment attribute |
| `unused` | Silence unused parameter warning |
| `arrsize` | ARRAY_SIZE macro |
| `cfgdef` | Overridable configuration default |
| `dbgmacro` | DBG() printf macro compiled out without DEBUG |
| `enumt` | typedef enum with trailing COUNT |
| `fnptr` | Function pointer typedef |
| `superloop` | Embedded main with init and super loop |

</details>

<details><summary><b>C only</b> (4)</summary>

| Prefix | Description |
| --- | --- |
| `sassert` | Compile-time size check |
| `module` | C source file layout |
| `sfn` | Static (file-local) function |
| `cleanup` | Error handling with goto cleanup |

</details>

<details><summary><b>C++ only</b> (17)</summary>

| Prefix | Description |
| --- | --- |
| `sassert` | Compile-time size check |
| `ns` | Namespace with closing comment |
| `anon` | Anonymous namespace |
| `class5` | Class with rule-of-five special members |
| `nocopy` | Delete copy/move operations |
| `singleton` | Meyers singleton accessor |
| `enumc` | Scoped enum with underlying type |
| `tfn` | Function template |
| `rfor` | Range-based for loop |
| `lam` | Lambda expression |
| `uptr` | std::make_unique |
| `sptr` | std::make_shared |
| `cexpr` | constexpr constant |
| `mmio` | Volatile register reference at a fixed address |
| `isrcpp` | ISR with C linkage so the vector table finds it |
| `gtest` | GoogleTest TEST |
| `gtestf` | GoogleTest fixture and TEST_F |

</details>

<details><summary><b>Rust</b> (16)</summary>

| Prefix | Description |
| --- | --- |
| `nostd` | Bare-metal no_std binary (cortex-m-rt) |
| `embassy` | Embassy async no_std binary |
| `etask` | Embassy task |
| `isr` | cortex-m-rt interrupt handler |
| `hardfault` | cortex-m-rt HardFault exception |
| `panich` | Custom #[panic_handler] |
| `cs` | critical_section::with |
| `shared` | Static shared with an interrupt |
| `dlog` | defmt logging macro |
| `implnew` | impl block with a new() constructor |
| `impldisplay` | Implement core::fmt::Display |
| `implfrom` | Implement From<T> |
| `errenum` | Error enum with Display and Error impls |
| `fnr` | Function returning Result |
| `tokmain` | #[tokio::main] with anyhow |
| `testr` | Test function returning Result |

</details>

<details><summary><b>Python</b> (15)</summary>

| Prefix | Description |
| --- | --- |
| `script` | CLI script skeleton with argparse and main() |
| `mainf` | main() with __main__ guard |
| `dclass` | dataclass |
| `enumc` | Enum class |
| `logger` | Module-level logger |
| `logcfg` | logging.basicConfig |
| `ctxmgr` | @contextmanager function |
| `subrun` | subprocess.run with checks and captured output |
| `readf` | Read a text file with pathlib |
| `serial` | pyserial: open port and read lines |
| `unpack` | struct.unpack binary data |
| `pack` | struct.pack binary data |
| `ptest` | pytest test function |
| `pfix` | pytest fixture |
| `pparam` | pytest.mark.parametrize |

</details>

<details><summary><b>CMake</b> (3)</summary>

| Prefix | Description |
| --- | --- |
| `cmproj` | CMakeLists.txt for a cross-compiled firmware |
| `cmtoolchain` | CMake toolchain file for a GCC cross compiler |
| `cmpostbuild` | Generate .bin/.hex and print size after build |

</details>

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
