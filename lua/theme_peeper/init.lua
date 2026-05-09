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

local function notify_error(err)
	vim.notify(err, vim.log.levels.ERROR)
end

local function notify_no_themes()
	vim.notify("No colorschemes found", vim.log.levels.WARN)
end

local function capture_without_cache(theme)
	return require("theme_peeper.capture").theme(theme, config.capture)
end

local function capture_with_cache(theme)
	local cache = require("theme_peeper.cache")
	local cached, key = cache.get(theme, config.capture)

	if cached then
		return cached, nil
	end

	local captured, err = capture_without_cache(theme)

	if not captured then
		return nil, err
	end

	cache.set(key, captured)

	return captured, nil
end

local function should_use_cache(opts)
	return opts.cache ~= false and config.cache.enabled
end

local function merged_preview_opts(opts)
	return vim.tbl_deep_extend("force", config.preview, opts or {})
end

function M.capture(theme, opts)
	opts = opts or {}

	if should_use_cache(opts) then
		return capture_with_cache(theme)
	end

	return capture_without_cache(theme)
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

	require("theme_peeper.preview").open(captured, merged_preview_opts(opts))

	return captured, nil
end

function M.browse()
	require("theme_peeper.browser").open(M.list())
end

function M.peek(theme)
	local _, err = M.preview(theme, {
		cache = true,
	})

	if err then
		notify_error(err)
	end
end

function M.select()
	local themes = M.list()

	if #themes == 0 then
		notify_no_themes()
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
		notify_error(err)
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
