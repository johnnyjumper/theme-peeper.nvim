local M = {}

local start_marker = "__THEME_PEEPER_START__"
local end_marker = "__THEME_PEEPER_END__"

local function build_child_script(payload)
	return string.format(
		[[
local payload = vim.json.decode(%q)

vim.o.termguicolors = payload.termguicolors
vim.o.background = payload.background

vim.opt.runtimepath = payload.runtime_paths

for key, value in pairs(payload.globals or {}) do
	vim.g[key] = value
end

pcall(vim.cmd, "highlight clear")
vim.g.colors_name = nil

for name, hl in pairs(payload.parent_highlights or {}) do
	if type(hl) == "table" and not vim.tbl_isempty(hl) then
		pcall(vim.api.nvim_set_hl, 0, name, hl)
	end
end

vim.cmd.colorscheme(payload.theme)

local highlights = require("theme_peeper.highlights")
local all_highlights = highlights.get_all_effective()

io.stdout:write("\n%s\n")
io.stdout:write(vim.json.encode({
	requested_theme = payload.theme,
	colors_name = vim.g.colors_name,
	background = vim.o.background,

	sonokai = {
		style = vim.g.sonokai_style,
		enable_italic = vim.g.sonokai_enable_italic,
		transparent_background = vim.g.sonokai_transparent_background,
		diagnostic_text_highlight = vim.g.sonokai_diagnostic_text_highlight,
		diagnostic_line_highlight = vim.g.sonokai_diagnostic_line_highlight,
		diagnostic_virtual_text = vim.g.sonokai_diagnostic_virtual_text,
	},

	normal = highlights.get_effective("Normal"),
	normal_float = highlights.get_effective("NormalFloat"),
	float_border = highlights.get_effective("FloatBorder"),
	float_title = highlights.get_effective("FloatTitle"),

	comment = highlights.get_effective("Comment"),
	string = highlights.get_effective("String"),
	func = highlights.get_effective("Function"),
	keyword = highlights.get_effective("Keyword"),
	visual = highlights.get_effective("Visual"),
	search = highlights.get_effective("Search"),
	cursor_line = highlights.get_effective("CursorLine"),

	highlights = all_highlights,
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

function M.theme(theme, opts)
	opts = opts or {}

	local state = require("theme_peeper.state")
	local payload = state.capture_payload(theme, opts)

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
