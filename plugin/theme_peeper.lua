local function theme_peeper()
	return require("theme_peeper")
end

local function complete_colorschemes()
	return vim.fn.getcompletion("", "color")
end

local function create_command(name, callback, opts)
	opts = vim.tbl_extend("force", {
		force = true,
	}, opts or {})

	vim.api.nvim_create_user_command(name, callback, opts)
end

local colorscheme_arg = {
	nargs = 1,
	complete = complete_colorschemes,
}

create_command("ThemePeep", function()
	theme_peeper().select()
end)

create_command("ThemePeepPreview", function(opts)
	theme_peeper().peek(opts.args)
end, colorscheme_arg)
