local M = {}

local function is_json_scalar(value)
	local value_type = type(value)

	return value_type == "string" or value_type == "number" or value_type == "boolean" or value == nil
end

local function normalize_global_name(name)
	name = name:gsub("^g:", "")
	name = name:gsub("^g%.", "")

	return name
end

local function read_global(name)
	local ok, value = pcall(function()
		return vim.g[name]
	end)

	if not ok then
		return nil, false
	end

	return value, true
end

local function add_global_if_safe(globals, raw_name)
	local name = normalize_global_name(raw_name)
	local value, ok = read_global(name)

	if ok and type(name) == "string" and is_json_scalar(value) then
		globals[name] = value
	end
end

function M.get_safe_globals()
	local globals = {}
	local names = vim.fn.getcompletion("g:", "var")

	for _, raw_name in ipairs(names) do
		add_global_if_safe(globals, raw_name)
	end

	return globals
end

local function user_globals(opts)
	opts = opts or {}

	return opts.globals or {}
end

local function merged_globals(opts)
	return vim.tbl_deep_extend("force", M.get_safe_globals(), user_globals(opts))
end

function M.capture_payload(theme, opts)
	return {
		theme = theme,
		runtime_paths = vim.api.nvim_list_runtime_paths(),
		globals = merged_globals(opts),
		termguicolors = vim.o.termguicolors,
		background = vim.o.background,
		current_colors_name = vim.g.colors_name,
	}
end

return M
