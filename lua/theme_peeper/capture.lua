local M = {}

local start_marker = "__THEME_PEEPER_START__"
local end_marker = "__THEME_PEEPER_END__"

local function child_script_template()
	return [[
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
]]
end

local function build_child_script(payload)
	return string.format(child_script_template(), vim.json.encode(payload), start_marker, end_marker)
end

local function write_child_script(script)
	local path = vim.fn.tempname() .. ".lua"

	vim.fn.writefile(vim.split(script, "\n"), path)

	return path
end

local function build_child_command(script_path)
	return {
		"nvim",
		"--headless",
		"--clean",
		"-n",
		"-c",
		"luafile " .. script_path,
		"-c",
		"qa!",
	}
end

local function run_child_script(script_path)
	return vim.system(build_child_command(script_path), {
		text = true,
	}):wait()
end

local function delete_child_script(script_path)
	pcall(vim.fn.delete, script_path)
end

local function extract_json(stdout)
	return stdout:match(start_marker .. "\n(.-)\n" .. end_marker)
end

local function format_child_error(message, theme, result)
	return table.concat({
		message .. theme,
		"",
		"stdout:",
		result.stdout,
		"",
		"stderr:",
		result.stderr,
	}, "\n")
end

local function decode_capture(theme, json)
	local ok, decoded = pcall(vim.json.decode, json)

	if not ok then
		return nil, "Failed to decode captured highlight JSON for theme: " .. theme
	end

	return decoded, nil
end

local function capture_payload(theme, opts)
	return require("theme_peeper.state").capture_payload(theme, opts)
end

function M.theme(theme, opts)
	opts = opts or {}

	local payload = capture_payload(theme, opts)
	local script = build_child_script(payload)
	local script_path = write_child_script(script)
	local result = run_child_script(script_path)

	delete_child_script(script_path)

	if result.code ~= 0 then
		return nil, format_child_error("Failed to capture theme: ", theme, result)
	end

	local json = extract_json(result.stdout)

	if not json then
		return nil, format_child_error("Failed to find captured highlight JSON for theme: ", theme, result)
	end

	return decode_capture(theme, json)
end

return M
