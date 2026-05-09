local source = debug.getinfo(1, "S").source
local current_file = source:sub(1, 1) == "@" and source:sub(2) or source
local plugin_root = vim.fn.fnamemodify(current_file, ":p:h:h")

local plenary_path = plugin_root .. "/.tests/plenary.nvim"

vim.opt.runtimepath:prepend(plenary_path)
vim.opt.runtimepath:prepend(plugin_root)
vim.opt.runtimepath:prepend(plugin_root .. "/tests")

vim.o.termguicolors = true
vim.o.background = "dark"

vim.cmd("runtime plugin/plenary.vim")
