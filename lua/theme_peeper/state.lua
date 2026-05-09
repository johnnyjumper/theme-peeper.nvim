local M = {}

local function is_json_safe(value)
	local value_type = type(value)

	return value_type == "string" or value_type == "number" or value_type == "boolean" or value == nil
end

local function normalize_global_name(name)
	name = name:gsub("^g:", "")
	name = name:gsub("^g%.", "")

	return name
end

function M.get_safe_globals()
	local globals = {}
	local names = vim.fn.getcompletion("g:", "var")

	for _, raw_name in ipairs(names) do
		local key = normalize_global_name(raw_name)

		local ok, value = pcall(function()
			return vim.g[key]
		end)

		if ok and type(key) == "string" and is_json_safe(value) then
			globals[key] = value
		end
	end

	return globals
end

local function capture_globals(opts)
	opts = opts or {}

	return vim.tbl_deep_extend("force", M.get_safe_globals(), opts.globals or {})
end

local function base_payload(opts)
	opts = opts or {}

	return {
		runtime_paths = vim.api.nvim_list_runtime_paths(),
		globals = capture_globals(opts),
		termguicolors = vim.o.termguicolors,
		background = vim.o.background,
		current_colors_name = vim.g.colors_name,
	}
end

function M.capture_payload(theme, opts)
	local payload = base_payload(opts)

	payload.theme = theme
	payload.parent_highlights = require("theme_peeper.highlights").get_all_effective()

	return payload
end

function M.cache_identity(theme, opts)
	local identity = base_payload(opts)

	identity.theme = theme

	return identity
end

return M
