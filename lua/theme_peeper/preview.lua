local M = {}

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

local function normalize_highlights(captured)
	local highlights = vim.deepcopy(captured.highlights or {})

	-- Critical:
	-- This is a floating preview, but we want it to look like a normal editor buffer.
	if not is_empty(captured.normal) then
		highlights.NormalFloat = vim.deepcopy(captured.normal)
		highlights.FloatBorder = vim.deepcopy(captured.normal)
		highlights.FloatTitle = vim.deepcopy(captured.normal)
	end

	if not is_empty(captured.normal) then
		highlights.EndOfBuffer = vim.deepcopy(captured.normal)
		highlights.SignColumn = vim.deepcopy(captured.normal)
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

function M.open(captured)
	local theme = captured.colors_name or captured.theme or "unknown"
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

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((ui.width - width) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. theme .. " ",
		title_pos = "center",
	})

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].winhighlight = ""

	local namespace = vim.api.nvim_create_namespace("theme-peeper:" .. theme)

	apply_highlights(namespace, captured)

	vim.api.nvim_win_set_hl_ns(win, namespace)

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

return M
