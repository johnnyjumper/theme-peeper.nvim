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

function M.peek(theme)
	local preview = require("theme_peeper.preview")

	-- Important:
	-- If a preview window is currently active, its highlight namespace can affect
	-- the captured effective highlight state and poison the cache key.
	preview.close()

	local captured, err = capture_theme(theme, true)

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	preview.open(captured, config.preview)
end

function M.debug(theme)
	local preview = require("theme_peeper.preview")
	local debug = require("theme_peeper.debug")

	preview.close()

	-- Debug should always be fresh.
	local captured, err = capture_theme(theme, false)

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	debug.open(captured)
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
