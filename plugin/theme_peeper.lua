vim.api.nvim_create_user_command("ThemePeek", function(opts)
	require("theme_peeper").peek(opts.args)
end, {
	nargs = 1,
	complete = function()
		return vim.fn.getcompletion("", "color")
	end,
})
