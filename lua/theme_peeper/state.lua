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

function M.snapshot(opts)
	opts = opts or {}

	local highlights = require("theme_peeper.highlights")

	local globals = vim.tbl_deep_extend("force", M.get_safe_globals(), opts.globals or {})

	return {
		runtime_paths = vim.api.nvim_list_runtime_paths(),
		parent_highlights = highlights.get_all_effective(),
		globals = globals,
		termguicolors = vim.o.termguicolors,
		background = vim.o.background,
		current_colors_name = vim.g.colors_name,
	}
end

function M.payload(theme, opts)
	local snapshot = M.snapshot(opts)
	snapshot.theme = theme
	return snapshot
end

return M
