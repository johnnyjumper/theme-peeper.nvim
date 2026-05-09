local M = {}

local WINDOW_WIDTH = 110
local WINDOW_HEIGHT = 32

local captured_groups = {
	"Normal",
	"NormalFloat",
	"FloatBorder",
	"FloatTitle",
	"Comment",
	"String",
	"Function",
	"Keyword",
	"Visual",
	"Search",
	"CursorLine",
}

local function append_inspected(lines, label, value)
	local inspected = vim.inspect(value)
	local parts = vim.split(inspected, "\n", { plain = true })

	if #parts == 0 then
		table.insert(lines, string.format("%-16s nil", label))
		return
	end

	table.insert(lines, string.format("%-16s %s", label, parts[1]))

	for i = 2, #parts do
		table.insert(lines, string.format("%-16s %s", "", parts[i]))
	end
end

local function group_lookup(captured)
	return {
		Normal = captured.normal,
		NormalFloat = captured.normal_float,
		FloatBorder = captured.float_border,
		FloatTitle = captured.float_title,
		Comment = captured.comment,
		String = captured.string,
		Function = captured.func,
		Keyword = captured.keyword,
		Visual = captured.visual,
		Search = captured.search,
		CursorLine = captured.cursor_line,
	}
end

local function append_header(lines, captured)
	table.insert(lines, "Theme Peeper Debug")
	table.insert(lines, "")
	table.insert(lines, "requested_theme = " .. tostring(captured.requested_theme))
	table.insert(lines, "colors_name     = " .. tostring(captured.colors_name))
	table.insert(lines, "background      = " .. tostring(captured.background))
end

local function append_sonokai(lines, captured)
	table.insert(lines, "")
	table.insert(lines, "Sonokai globals:")
	table.insert(lines, "")

	append_inspected(lines, "sonokai", captured.sonokai)
end

local function append_captured_groups(lines, captured)
	local lookup = group_lookup(captured)

	table.insert(lines, "")
	table.insert(lines, "Captured groups:")
	table.insert(lines, "")

	for _, group in ipairs(captured_groups) do
		append_inspected(lines, group, lookup[group])
	end
end

local function debug_lines(captured)
	local lines = {}

	append_header(lines, captured)
	append_sonokai(lines, captured)
	append_captured_groups(lines, captured)

	return lines
end

local function create_buffer(lines)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.bo[buf].filetype = "lua"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	return buf
end

local function window_config(lines)
	local ui = vim.api.nvim_list_uis()[1]
	local height = math.min(#lines, WINDOW_HEIGHT)

	return {
		relative = "editor",
		width = WINDOW_WIDTH,
		height = height,
		col = math.floor((ui.width - WINDOW_WIDTH) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Theme Peeper Debug ",
		title_pos = "center",
	}
end

local function close_window(win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function set_keymaps(buf, win)
	vim.keymap.set("n", "q", function()
		close_window(win)
	end, { buffer = buf })

	vim.keymap.set("n", "<Esc>", function()
		close_window(win)
	end, { buffer = buf })
end

function M.open(captured)
	local lines = debug_lines(captured)
	local buf = create_buffer(lines)
	local win = vim.api.nvim_open_win(buf, true, window_config(lines))

	set_keymaps(buf, win)
end

return M
