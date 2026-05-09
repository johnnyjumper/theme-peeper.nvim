local M = {}

local store = {}
local stats = {
	hits = 0,
	misses = 0,
}

local function count_entries()
	local count = 0

	for _ in pairs(store) do
		count = count + 1
	end

	return count
end

local function sorted_keys(value)
	local keys = {}

	for key in pairs(value) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)

	return keys
end

local function stable_encode(value)
	local value_type = type(value)

	if value == nil then
		return "nil"
	end

	if value_type == "string" then
		return vim.inspect(value)
	end

	if value_type == "number" or value_type == "boolean" then
		return tostring(value)
	end

	if value_type ~= "table" then
		return "<" .. value_type .. ">"
	end

	local parts = { "{" }

	for _, key in ipairs(sorted_keys(value)) do
		table.insert(parts, stable_encode(key))
		table.insert(parts, "=")
		table.insert(parts, stable_encode(value[key]))
		table.insert(parts, ";")
	end

	table.insert(parts, "}")

	return table.concat(parts)
end

local function get_nvim_version()
	local version = vim.version()

	return {
		major = version.major,
		minor = version.minor,
		patch = version.patch,
	}
end

local function get_relevant_globals(opts)
	opts = opts or {}

	local globals = {}
	local configured_globals = opts.globals or {}

	for key, value in pairs(configured_globals) do
		globals[key] = value
	end

	-- These are known to affect your current theme setup.
	-- Do not include every vim.g value here. That makes the cache unstable.
	local known_theme_globals = {
		"sonokai_style",
		"sonokai_enable_italic",
		"sonokai_transparent_background",
		"sonokai_diagnostic_text_highlight",
		"sonokai_diagnostic_line_highlight",
		"sonokai_diagnostic_virtual_text",

		"gruvbox_material_background",
		"gruvbox_material_foreground",
		"gruvbox_material_enable_italic",

		"catppuccin_flavour",
		"catppuccin_flavor",
	}

	for _, key in ipairs(known_theme_globals) do
		local value = vim.g[key]

		if value ~= nil then
			globals[key] = value
		end
	end

	return globals
end

local function build_fingerprint(theme, opts)
	return {
		schema = 1,
		theme = theme,
		current_colors_name = vim.g.colors_name,
		background = vim.o.background,
		termguicolors = vim.o.termguicolors,
		runtime_paths = vim.api.nvim_list_runtime_paths(),
		globals = get_relevant_globals(opts),
		nvim = get_nvim_version(),
	}
end

function M.key(theme, opts)
	local fingerprint = build_fingerprint(theme, opts)

	return vim.fn.sha256(stable_encode(fingerprint))
end

function M.get(theme, opts)
	local key = M.key(theme, opts)
	local cached = store[key]

	if cached then
		stats.hits = stats.hits + 1
		return vim.deepcopy(cached), key
	end

	stats.misses = stats.misses + 1
	return nil, key
end

function M.set(key, captured)
	store[key] = vim.deepcopy(captured)
end

function M.clear()
	store = {}
	stats.hits = 0
	stats.misses = 0
end

function M.info()
	return {
		entries = count_entries(),
		hits = stats.hits,
		misses = stats.misses,
	}
end

return M
