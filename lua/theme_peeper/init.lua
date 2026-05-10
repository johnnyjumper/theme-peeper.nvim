local M = {}

local function config()
	return require("theme_peeper.config").get()
end

local function notify_error(message)
	vim.notify(tostring(message), vim.log.levels.ERROR)
end

local function notify_no_themes()
	vim.notify("No colorschemes found", vim.log.levels.WARN)
end

local function capture_without_cache(theme)
	return require("theme_peeper.capture").theme(theme, config().capture)
end

local function capture_with_cache(theme)
	local cache = require("theme_peeper.cache")
	local cached = cache.get(theme, config().capture)

	if cached then
		return cached, nil
	end

	local captured, err = capture_without_cache(theme)

	if not captured then
		return nil, err
	end

	cache.set(theme, config().capture, captured)

	return captured, nil
end

local function should_use_cache(opts)
	return opts.cache ~= false and config().cache.enabled
end

local function merged_float_opts(opts)
	return vim.tbl_deep_extend("force", config().preview, opts or {})
end

local function configured_apply()
	local apply = config().apply

	if type(apply) ~= "function" then
		return nil, "Theme Peeper apply must be a function"
	end

	return apply, nil
end

local function apply_theme(theme)
	local apply, err = configured_apply()

	if not apply then
		notify_error(err)
		return false
	end

	local ok, apply_err = pcall(apply, theme)

	if not ok then
		notify_error(apply_err)
		return false
	end

	return true
end

function M.setup(opts)
	require("theme_peeper.config").setup(opts or {})
end

function M.config()
	return config()
end

function M.list()
	local themes = vim.fn.getcompletion("", "color")
	table.sort(themes)

	return themes
end

function M.capture(theme, opts)
	opts = opts or {}

	if should_use_cache(opts) then
		return capture_with_cache(theme)
	end

	return capture_without_cache(theme)
end

function M.actions()
	return require("theme_peeper.actions").new(config())
end

function M.open(captured, opts)
	return require("theme_peeper.previewers.float").open(captured, merged_float_opts(opts))
end

function M.close()
	require("theme_peeper.previewers").close()
end

function M.apply(theme)
	if not theme or theme == "" then
		notify_error("Missing colorscheme")
		return false
	end

	return apply_theme(theme)
end

function M.confirm(theme, opts)
	opts = opts or {}

	if opts.close_preview ~= false then
		M.close()
	end

	return M.apply(theme)
end

function M.preview(theme, opts)
	opts = opts or {}

	if not theme or theme == "" then
		return nil, "Missing colorscheme"
	end

	local previewed, err = require("theme_peeper.previewers").preview(M.actions(), theme, opts)

	if not previewed then
		return nil, err
	end

	return true, nil
end

function M.peek(theme)
	local ok, err = M.preview(theme, {
		cache = true,
	})

	if not ok and err then
		notify_error(err)
	end
end

function M.select()
	local themes = M.list()

	if #themes == 0 then
		notify_no_themes()
		return
	end

	return require("theme_peeper.pickers").open(config(), M.actions())
end

return M
