local M = {}

local config = {
	capture = {},
	preview = {},
	cache = {
		enabled = true,
	},
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

function M.list()
	local themes = vim.fn.getcompletion("", "color")
	table.sort(themes)
	return themes
end

local function capture_theme(theme, use_cache)
	local capture = require("theme_peeper.capture")

	if not use_cache or not config.cache.enabled then
		return capture.theme(theme, config.capture)
	end

	local cache = require("theme_peeper.cache")
	local cached, key = cache.get(theme, config.capture)

	if cached then
		return cached, nil
	end

	local captured, err = capture.theme(theme, config.capture)

	if not captured then
		return nil, err
	end

	cache.set(key, captured)

	return captured, nil
end

function M.capture(theme, opts)
	opts = opts or {}

	local use_cache = opts.cache ~= false
	return capture_theme(theme, use_cache)
end

function M.open(captured)
	require("theme_peeper.preview").open(captured, config.preview)
end

function M.close()
	require("theme_peeper.preview").close()
end

function M.preview(theme, opts)
	opts = opts or {}

	M.close()

	local captured, err = M.capture(theme, {
		cache = opts.cache,
	})

	if not captured then
		return nil, err
	end

	M.open(captured)

	return captured, nil
end

function M.peek(theme)
	local _, err = M.preview(theme, {
		cache = true,
	})

	if err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end

function M.select()
	local themes = M.list()

	if #themes == 0 then
		vim.notify("No colorschemes found", vim.log.levels.WARN)
		return
	end

	vim.ui.select(themes, {
		prompt = "Select colorscheme",
	}, function(theme)
		if not theme then
			return
		end

		M.peek(theme)
	end)
end

function M.debug(theme)
	M.close()

	local captured, err = M.capture(theme, {
		cache = false,
	})

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	require("theme_peeper.debug").open(captured)
end

function M.clear_cache()
	require("theme_peeper.cache").clear()
	vim.notify("Theme Peeper cache cleared")
end

function M.cache_info()
	local info = require("theme_peeper.cache").info()

	vim.notify(table.concat({
		"Theme Peeper cache",
		"entries: " .. info.entries,
		"hits: " .. info.hits,
		"misses: " .. info.misses,
	}, "\n"))
end

return M
