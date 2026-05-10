local M = {}

local extmark_namespace_name = "theme-peeper.render"
local highlight_namespace_name = "theme-peeper.render.highlights"
local extmark_priority = 20000
local group_prefix = "ThemePeeperPreview"

local defined_groups = {}

local fallback_groups = {
	Identifier = "Normal",
	Constant = "String",
	Boolean = "Constant",
	DiagnosticError = "ErrorMsg",
	DiagnosticWarn = "WarningMsg",
	DiagnosticInfo = "Normal",
	DiagnosticHint = "Comment",
}

local explicit_captured_groups = {
	Normal = "normal",
	NormalFloat = "normal_float",
	FloatBorder = "float_border",
	FloatTitle = "float_title",
	Comment = "comment",
	String = "string",
	Function = "func",
	Keyword = "keyword",
	Visual = "visual",
	Search = "search",
	CursorLine = "cursor_line",
}

local default_groups = {
	"Normal",
	"NormalFloat",
	"EndOfBuffer",
	"SignColumn",
	"FloatBorder",
	"FloatTitle",
	"CursorLine",
	"Comment",
	"String",
	"Function",
	"Keyword",
	"Visual",
	"Search",
	"IncSearch",
	"Pmenu",
	"PmenuSel",
	"Identifier",
	"Constant",
	"Boolean",
	"DiagnosticError",
	"DiagnosticWarn",
	"DiagnosticInfo",
	"DiagnosticHint",
	"ErrorMsg",
	"WarningMsg",
	"StatusLine",
	"WinSeparator",
	"LineNr",
	"Folded",
}

local window_groups = {
	"Normal",
	"NormalFloat",
	"EndOfBuffer",
	"SignColumn",
	"FloatBorder",
	"FloatTitle",
	"CursorLine",
}

local function sample_opts(opts)
	if opts and opts.preview then
		return opts.preview
	end

	return opts or {}
end

local function current_sample(opts)
	return require("theme_peeper.samples").resolve(sample_opts(opts))
end

local function is_empty(value)
	return value == nil or vim.tbl_isempty(value)
end

local function theme_name(captured)
	return captured.colors_name or captured.requested_theme or "unknown"
end

local function copied(value)
	if type(value) ~= "table" or vim.tbl_isempty(value) then
		return nil
	end

	return vim.deepcopy(value)
end

local function highlight_map(captured)
	local highlights = vim.deepcopy(captured.highlights or {})

	for highlight_name, captured_key in pairs(explicit_captured_groups) do
		if not is_empty(captured[captured_key]) then
			highlights[highlight_name] = vim.deepcopy(captured[captured_key])
		end
	end

	if not is_empty(captured.normal) then
		highlights.Normal = vim.deepcopy(captured.normal)
		highlights.NormalFloat = vim.deepcopy(captured.normal)
		highlights.EndOfBuffer = vim.deepcopy(captured.normal)
		highlights.SignColumn = vim.deepcopy(captured.normal)
	end

	return highlights
end

local function group_value(highlights, name)
	local value = copied(highlights[name])

	if value then
		return value
	end

	local fallback = fallback_groups[name]

	if fallback then
		return group_value(highlights, fallback)
	end

	return copied(highlights.Normal)
end

local function preview_group(name)
	return group_prefix .. name
end

local function set_hl(namespace, name, value)
	if not value then
		return
	end

	pcall(vim.api.nvim_set_hl, namespace, name, value)
end

local function clear_hl(namespace, name)
	pcall(vim.api.nvim_set_hl, namespace, name, {})
end

local function add_group(groups, seen, name)
	if type(name) ~= "string" or name == "" or seen[name] then
		return
	end

	seen[name] = true
	table.insert(groups, name)
end

local function sample_groups(sample)
	local groups = {}
	local seen = {}

	for _, name in ipairs(default_groups) do
		add_group(groups, seen, name)
	end

	for _, name in ipairs(sample.groups or {}) do
		add_group(groups, seen, name)
	end

	for _, span in ipairs(sample.spans or {}) do
		add_group(groups, seen, span.group)
	end

	return groups
end

local function define_span_groups(namespace, highlights, groups)
	for _, name in ipairs(groups) do
		defined_groups[name] = true
		set_hl(namespace, preview_group(name), group_value(highlights, name))
	end
end

local function define_window_groups(namespace, highlights)
	local normal = group_value(highlights, "Normal")

	set_hl(namespace, "Normal", normal)
	set_hl(namespace, "NormalFloat", normal)
	set_hl(namespace, "EndOfBuffer", normal)
	set_hl(namespace, "SignColumn", normal)
	set_hl(namespace, "FloatBorder", group_value(highlights, "FloatBorder"))
	set_hl(namespace, "FloatTitle", group_value(highlights, "FloatTitle"))
	set_hl(namespace, "CursorLine", group_value(highlights, "CursorLine"))
end

local function define_preview_groups(namespace, captured, sample)
	local highlights = highlight_map(captured)
	local groups = sample_groups(sample)

	define_span_groups(namespace, highlights, groups)
	define_window_groups(namespace, highlights)
end

local function clear_preview_groups(namespace)
	for name in pairs(defined_groups) do
		clear_hl(namespace, preview_group(name))
		defined_groups[name] = nil
	end

	for _, name in ipairs(window_groups) do
		clear_hl(namespace, name)
	end
end

local function word_range(line, word)
	local start_col = line:find(word, 1, true)

	if not start_col then
		return nil, nil
	end

	return start_col - 1, start_col - 1 + #word
end

local function pattern_range(line, pattern)
	local start_col, end_col = line:find(pattern)

	if not start_col then
		return nil, nil
	end

	return start_col - 1, end_col
end

local function span_range(line, span)
	if type(span.start_col) == "number" and type(span.end_col) == "number" then
		return span.start_col, span.end_col
	end

	if type(span.word) == "string" then
		return word_range(line, span.word)
	end

	if type(span.pattern) == "string" then
		return pattern_range(line, span.pattern)
	end

	return nil, nil
end

local function set_buffer_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function apply_buffer_options(buf)
	vim.bo[buf].filetype = ""
	vim.bo[buf].syntax = "off"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
end

local function apply_window_options(win, highlight_namespace)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	vim.wo[win].list = false
	vim.wo[win].spell = false
	vim.wo[win].colorcolumn = ""
	vim.wo[win].cursorline = false
	vim.wo[win].winhighlight = ""

	pcall(vim.api.nvim_win_set_hl_ns, win, highlight_namespace)
end

local function add_span_highlight(buf, namespace, span, lines)
	local line = lines[span.line]

	if type(line) ~= "string" or type(span.group) ~= "string" then
		return
	end

	local start_col, end_col = span_range(line, span)

	if not start_col or not end_col or end_col <= start_col then
		return
	end

	vim.api.nvim_buf_set_extmark(buf, namespace, span.line - 1, start_col, {
		end_col = end_col,
		hl_group = preview_group(span.group),
		priority = extmark_priority,
	})
end

function M.theme_name(captured)
	return theme_name(captured)
end

function M.lines(opts)
	return vim.deepcopy(current_sample(opts).lines)
end

function M.render(opts)
	local buf = opts.buf
	local win = opts.win
	local captured = opts.captured
	local sample = current_sample(opts)

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return nil, "invalid preview buffer"
	end

	if not captured then
		return nil, "missing captured theme"
	end

	local extmark_namespace = vim.api.nvim_create_namespace(extmark_namespace_name)
	local highlight_namespace = vim.api.nvim_create_namespace(highlight_namespace_name)

	vim.api.nvim_buf_clear_namespace(buf, extmark_namespace, 0, -1)
	clear_preview_groups(highlight_namespace)
	define_preview_groups(highlight_namespace, captured, sample)
	set_buffer_lines(buf, sample.lines)
	apply_buffer_options(buf)

	for _, span in ipairs(sample.spans or {}) do
		add_span_highlight(buf, extmark_namespace, span, sample.lines)
	end

	if win and vim.api.nvim_win_is_valid(win) then
		apply_window_options(win, highlight_namespace)
	end

	return true, nil
end

function M.clear(buf, win)
	local extmark_namespace = vim.api.nvim_create_namespace(extmark_namespace_name)
	local highlight_namespace = vim.api.nvim_create_namespace(highlight_namespace_name)

	if buf and vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_clear_namespace(buf, extmark_namespace, 0, -1)
	end

	if win and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_set_hl_ns, win, 0)
	end

	clear_preview_groups(highlight_namespace)
end

function M.error_preview(message)
	return {
		text = "Theme Peeper preview failed\n\n" .. tostring(message),
		ft = "text",
		loc = false,
	}
end

return M
