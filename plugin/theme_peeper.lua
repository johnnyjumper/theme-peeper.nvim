local function complete_colorschemes()
	return vim.fn.getcompletion("", "color")
end

vim.api.nvim_create_user_command("ThemePeep", function(opts)
	require("theme_peeper").peek(opts.args)
end, {
	nargs = 1,
	complete = complete_colorschemes,
})

vim.api.nvim_create_user_command("ThemePeepSelect", function()
	require("theme_peeper").select()
end, {})

vim.api.nvim_create_user_command("ThemePeeperDebug", function(opts)
	require("theme_peeper").debug(opts.args)
end, {
	nargs = 1,
	complete = complete_colorschemes,
})

vim.api.nvim_create_user_command("ThemePeeperCacheClear", function()
	require("theme_peeper").clear_cache()
end, {})

vim.api.nvim_create_user_command("ThemePeeperCacheInfo", function()
	require("theme_peeper").cache_info()
end, {})

vim.api.nvim_create_user_command("ThemePeepBrowse", function()
	require("theme_peeper").browse()
end, {})
