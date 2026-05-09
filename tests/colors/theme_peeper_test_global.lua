vim.cmd("highlight clear")
vim.g.colors_name = "theme_peeper_test_global"

local bg = vim.g.theme_peeper_test_bg or "#101010"
local fg = vim.g.theme_peeper_test_fg or "#eeeeee"

vim.api.nvim_set_hl(0, "Normal", {
	fg = fg,
	bg = bg,
})

vim.api.nvim_set_hl(0, "NormalFloat", {
	fg = fg,
	bg = "#202020",
})

vim.api.nvim_set_hl(0, "Comment", {
	fg = "#777777",
	italic = true,
})

vim.api.nvim_set_hl(0, "String", {
	fg = "#99cc99",
})

vim.api.nvim_set_hl(0, "Function", {
	fg = "#6699cc",
	bold = true,
})

vim.api.nvim_set_hl(0, "Keyword", {
	fg = "#cc6666",
})
