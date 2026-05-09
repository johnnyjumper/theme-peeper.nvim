local M = {}

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

local function normalize_highlights(captured)
	local highlights = vim.deepcopy(captured.highlights or {})

	-- The preview is technically a floating window.
	-- But visually we want to preview a normal editor buffer.
	if not is_empty(captured.normal) then
		highlights.Normal = vim.deepcopy(captured.normal)
		highlights.NormalFloat = vim.deepcopy(captured.normal)
		highlights.EndOfBuffer = vim.deepcopy(captured.normal)
		highlights.SignColumn = vim.deepcopy(captured.normal)
	end

	-- Keep theme-native float border/title if captured.
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

local function create_preview_namespace(theme)
	return vim.api.nvim_create_namespace("theme-peeper.preview." .. theme .. "." .. tostring(vim.uv.hrtime()))
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
	-- 0-based line numbers.
	highlight_word(buf, namespace, 19, "Normal", "Normal")
	highlight_word(buf, namespace, 19, "Comment", "Comment")
	highlight_word(buf, namespace, 19, "String", "String")
	highlight_word(buf, namespace, 19, "Function", "Function")
	highlight_word(buf, namespace, 19, "Keyword", "Keyword")

	highlight_word(buf, namespace, 20, "Visual", "Visual")
	highlight_word(buf, namespace, 20, "Search", "Search")
	highlight_word(buf, namespace, 20, "CursorLine", "CursorLine")
	highlight_word(buf, namespace, 20, "Pmenu", "Pmenu")
	highlight_word(buf, namespace, 20, "FloatBorder", "FloatBorder")
end

function M.open(captured, _opts)
	close_existing_preview()

	local theme = captured.colors_name or captured.requested_theme or "unknown"
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, sample_lines)

	vim.bo[buf].filetype = "lua"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	local ui = vim.api.nvim_list_uis()[1]
	local width = 80
	local height = math.min(#sample_lines, 24)

	local enter = _opts == nil or _opts.enter ~= false
	local win = vim.api.nvim_open_win(buf, enter, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((ui.width - width) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. theme .. " ",
		title_pos = "center",
		zindex = 80,
	})

	state.win = win
	state.buf = buf

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].winhighlight = ""

	local namespace = create_preview_namespace(theme)

	apply_highlights(namespace, captured)

	vim.api.nvim_win_set_hl_ns(win, namespace)

	decorate_sample_groups(buf, namespace)

	local function close()
		close_existing_preview()
	end

	vim.keymap.set("n", "q", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

function M.close()
	close_existing_preview()
end

return M
