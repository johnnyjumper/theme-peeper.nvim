local M = {}

local function picker_name(spec)
	if type(spec) == "string" then
		return spec
	end

	if type(spec) == "table" then
		return spec.name or spec[1] or "builtin"
	end

	return "builtin"
end

local function picker_opts(config, name, spec)
	local opts = vim.deepcopy((config.pickers or {})[name] or {})

	if type(spec) == "table" then
		opts = vim.tbl_deep_extend("force", opts, spec)
		opts.name = nil
		opts[1] = nil
	end

	return opts
end

local function custom_picker_opts(config, spec)
	local opts = vim.deepcopy((config.pickers or {}).custom or {})

	if opts.max_height == nil then
		opts.max_height = 12
	end

	if type(spec) == "table" then
		opts = vim.tbl_deep_extend("force", opts, spec)
		opts.open = nil
	end

	return opts
end

local function open_custom_picker(config, spec, actions)
	local opts = custom_picker_opts(config, spec)

	if type(spec) == "function" then
		return spec(actions, opts)
	end

	if type(spec) == "table" and type(spec.open) == "function" then
		return spec.open(actions, opts)
	end

	return nil
end

function M.open(config, actions)
	local spec = config.picker

	if type(spec) == "function" or type(spec) == "table" and type(spec.open) == "function" then
		return open_custom_picker(config, spec, actions)
	end

	local name = picker_name(spec)
	local ok, picker = pcall(require, "theme_peeper.pickers." .. name)

	if not ok then
		vim.notify("Theme Peeper picker not found: " .. name, vim.log.levels.ERROR)
		picker = require("theme_peeper.pickers.builtin")
		name = "builtin"
	end

	return picker.open(actions, picker_opts(config, name, spec))
end

return M
