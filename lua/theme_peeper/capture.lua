local M = {}

local start_marker = "__THEME_PEEPER_START__"
local end_marker = "__THEME_PEEPER_END__"

local function is_json_safe(value)
	local value_type = type(value)

	return value_type == "string" or value_type == "number" or value_type == "boolean" or value == nil
end

local function get_safe_globals()
	local globals = {}

	for key, value in pairs(vim.g) do
		if type(key) == "string" and is_json_safe(value) then
			globals[key] = value
		end
	end

	return globals
end

local function build_child_script(payload)
	return string.format(
		[[
local payload = vim.json.decode(%q)

vim.o.termguicolors = payload.termguicolors
vim.o.background = payload.background

for _, path in ipairs(payload.runtime_paths) do
	pcall(function()
		vim.opt.runtimepath:append(path)
	end)
end

for key, value in pairs(payload.globals or {}) do
	vim.g[key] = value
end

-- Start from the exact current parent highlight state.
for name, hl in pairs(payload.parent_highlights or {}) do
	if type(hl) == "table" and not vim.tbl_isempty(hl) then
		pcall(vim.api.nvim_set_hl, 0, name, hl)
	end
end

-- Now simulate the real operation we want to preview.
vim.cmd.colorscheme(payload.theme)

local highlights = vim.api.nvim_get_hl(0, { link = false })

local function get(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

io.stdout:write("\n%s\n")
io.stdout:write(vim.json.encode({
	theme = payload.theme,
	colors_name = vim.g.colors_name,
	background = vim.o.background,
	normal = get("Normal"),
	normal_float = get("NormalFloat"),
	float_border = get("FloatBorder"),
	comment = get("Comment"),
	string = get("String"),
	func = get("Function"),
	keyword = get("Keyword"),
	highlights = highlights,
}))
io.stdout:write("\n%s\n")
]],
		vim.json.encode(payload),
		start_marker,
		end_marker
	)
end

local function extract_json(stdout)
	return stdout:match(start_marker .. "\n(.-)\n" .. end_marker)
end

function M.theme(theme, _opts)
	local payload = {
		theme = theme,
		runtime_paths = vim.api.nvim_list_runtime_paths(),
		parent_highlights = vim.api.nvim_get_hl(0, { link = false }),
		globals = get_safe_globals(),
		termguicolors = vim.o.termguicolors,
		background = vim.o.background,
	}

	local script_path = vim.fn.tempname() .. ".lua"
	local script = build_child_script(payload)

	vim.fn.writefile(vim.split(script, "\n"), script_path)

	local result = vim.system({
		"nvim",
		"--headless",
		"--clean",
		"-n",
		"-c",
		"luafile " .. script_path,
		"-c",
		"qa!",
	}, {
		text = true,
	}):wait()

	pcall(vim.fn.delete, script_path)

	if result.code ~= 0 then
		return nil,
			table.concat({
				"Failed to capture theme: " .. theme,
				"",
				"stdout:",
				result.stdout,
				"",
				"stderr:",
				result.stderr,
			}, "\n")
	end

	local json = extract_json(result.stdout)

	if not json then
		return nil,
			table.concat({
				"Failed to find captured highlight JSON for theme: " .. theme,
				"",
				"stdout:",
				result.stdout,
				"",
				"stderr:",
				result.stderr,
			}, "\n")
	end

	local ok, decoded = pcall(vim.json.decode, json)

	if not ok then
		return nil, "Failed to decode captured highlight JSON for theme: " .. theme
	end

	return decoded, nil
end

return M
