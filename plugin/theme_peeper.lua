local function theme_peeper()
	return require("theme_peeper")
end

local function complete_colorschemes()
	return vim.fn.getcompletion("", "color")
end

local function create_command(name, callback, opts)
	vim.api.nvim_create_user_command(name, callback, opts or {})
end

local colorscheme_arg = {
	nargs = 1,
	complete = complete_colorschemes,
}

create_command("ThemePeep", function(opts)
	theme_peeper().peek(opts.args)
end, colorscheme_arg)

create_command("ThemePeepSelect", function()
	theme_peeper().select()
end)

create_command("ThemePeeperDebug", function(opts)
	theme_peeper().debug(opts.args)
end, colorscheme_arg)

create_command("ThemePeeperCacheClear", function()
	theme_peeper().clear_cache()
end)

create_command("ThemePeeperCacheInfo", function()
	theme_peeper().cache_info()
end)

create_command("ThemePeepBrowse", function()
	theme_peeper().browse()
end)
