local M = {}

local preview_width = 80
local preview_max_height = 24
local preview_zindex = 80

local state = {
	win = nil,
	buf = nil,
}

local sample_lines = {
	"local function create_user(input)",
	'  local name = input.name or "Johnny"',
	"",
	"  if name == nil then",
	'    error("missing name")',
	"  end",
	"",
	"  return {",
	"    id = 1,",
	"    name = name,",
	"    active = true,",
	"  }",
	"end",
	"",
	"-- Diagnostics",
	"-- Error: type mismatch",
	"-- Warning: unused variable",
	"-- Hint: extract function",
	"",
	"Normal  Comment  String  Function  Keyword",
	"Visual  Search   CursorLine  Pmenu  FloatBorder",
}

local sample_groups = {
	{ line = 19, word = "Normal", group = "Normal" },
	{ line = 19, word = "Comment", group = "Comment" },
	{ line = 19, word = "String", group = "String" },
	{ line = 19, word = "Function", group = "Function" },
	{ line = 19, word = "Keyword", group = "Keyword" },
	{ line = 20, word = "Visual", group = "Visual" },
	{ line = 20, word = "Search", group = "Search" },
	{ line = 20, word = "CursorLine", group = "CursorLine" },
	{ line = 20, word = "Pmenu", group = "Pmenu" },
	{ line = 20, word = "FloatBorder", group = "FloatBorder" },
}

local function is_empty(value)
	return value == nil or vim.tbl_isempty(value)
end

local function close_existing_preview()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
	state.buf = nil
end

local function theme_name(captured)
	return captured.colors_name or captured.requested_theme or "unknown"
end

local function normalize_highlights(captured)
	local highlights = vim.deepcopy(captured.highlights or {})

	if not is_empty(captured.normal) then
		highlights.Normal = vim.deepcopy(captured.normal)
		highlights.NormalFloat = vim.deepcopy(captured.normal)
		highlights.EndOfBuffer = vim.deepcopy(captured.normal)
		highlights.SignColumn = vim.deepcopy(captured.normal)
	end

	if not is_empty(captured.float_border) then
		highlights.FloatBorder = vim.deepcopy(captured.float_border)
	end

	if not is_empty(captured.float_title) then
		highlights.FloatTitle = vim.deepcopy(captured.float_title)
	end

	return highlights
end

local function apply_highlights(namespace, captured)
	local highlights = normalize_highlights(captured)

	for name, value in pairs(highlights) do
		if type(value) == "table" and not vim.tbl_isempty(value) then
			pcall(vim.api.nvim_set_hl, namespace, name, value)
		end
	end
end

local function create_namespace(theme)
	return vim.api.nvim_create_namespace("theme-peeper.preview." .. theme .. "." .. tostring(vim.uv.hrtime()))
end

local function create_buffer()
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, sample_lines)

	vim.bo[buf].filetype = "lua"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	return buf
end

local function window_config(theme)
	local ui = vim.api.nvim_list_uis()[1]
	local height = math.min(#sample_lines, preview_max_height)

	return {
		relative = "editor",
		width = preview_width,
		height = height,
		col = math.floor((ui.width - preview_width) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. theme .. " ",
		title_pos = "center",
		zindex = preview_zindex,
	}
end

local function open_window(buf, theme, opts)
	local enter = opts == nil or opts.enter ~= false

	return vim.api.nvim_open_win(buf, enter, window_config(theme))
end

local function apply_window_options(win)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].winhighlight = ""
end

local function highlight_word(buf, namespace, line, word, group)
	local text = vim.api.nvim_buf_get_lines(buf, line, line + 1, false)[1]

	if not text then
		return
	end

	local start_col = text:find(word, 1, true)

	if not start_col then
		return
	end

	vim.api.nvim_buf_set_extmark(buf, namespace, line, start_col - 1, {
		end_col = start_col - 1 + #word,
		hl_group = group,
	})
end

local function decorate_sample_groups(buf, namespace)
	for _, item in ipairs(sample_groups) do
		highlight_word(buf, namespace, item.line, item.word, item.group)
	end
end

local function apply_preview_namespace(win, buf, captured, theme)
	local namespace = create_namespace(theme)

	apply_highlights(namespace, captured)
	vim.api.nvim_win_set_hl_ns(win, namespace)
	decorate_sample_groups(buf, namespace)
end

local function set_keymaps(buf)
	vim.keymap.set("n", "q", close_existing_preview, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close_existing_preview, { buffer = buf })
end

function M.open(captured, opts)
	close_existing_preview()

	local theme = theme_name(captured)
	local buf = create_buffer()
	local win = open_window(buf, theme, opts)

	state.win = win
	state.buf = buf

	apply_window_options(win)
	apply_preview_namespace(win, buf, captured, theme)
	set_keymaps(buf)
end

function M.close()
	close_existing_preview()
end

return M
