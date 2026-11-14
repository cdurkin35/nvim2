-- Merged over nvim-lspconfig's clangd definition.
-- --query-driver lets clangd ask cross compilers (arm-none-eabi-gcc, riscv64-unknown-elf-gcc,
-- xtensa-esp32-elf-gcc, ...) for their built-in include paths and target defines, which is what
-- makes embedded projects resolve <stdint.h>, CMSIS, etc. from compile_commands.json.
return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=never",
        "--completion-style=detailed",
        "--function-arg-placeholders=true",
        "--fallback-style=webkit",
        "--query-driver=**/*-gcc,**/*-g++,**/*-gcc-*,**/*-g++-*,**/*-clang,**/*-clang++,/usr/bin/gcc,/usr/bin/g++,/usr/bin/clang,/usr/bin/clang++",
        "-j=4",
    },
    init_options = {
        clangdFileStatus = true,
        usePlaceholders = true,
        completeUnimported = true,
    },
}
