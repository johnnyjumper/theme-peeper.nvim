vim.api.nvim_create_user_command("ThemePeep", function(opts)
	require("theme_peeper").peek(opts.args)
end, {
	nargs = 1,
	complete = function()
		return vim.fn.getcompletion("", "color")
	end,
})

vim.api.nvim_create_user_command("ThemePeeperDebug", function(opts)
	require("theme_peeper").debug(opts.args)
end, {
	nargs = 1,
	complete = function()
		return vim.fn.getcompletion("", "color")
	end,
})
