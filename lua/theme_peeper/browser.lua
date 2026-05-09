local M = {}

local browser_min_width = 34
local browser_max_width = 54
local browser_min_height = 10
local browser_max_height = 24
local browser_height_ratio = 0.7
local browser_preview_width = 80
local browser_preview_gap = 3
local browser_left_margin = 2
local browser_zindex = 90
local preview_delay_ms = 120

local state = {
	win = nil,
	buf = nil,
	timer = nil,
}

local function close_timer()
	if not state.timer then
		return
	end

	state.timer:stop()
	state.timer:close()
	state.timer = nil
end

local function close_window()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
	state.buf = nil
end

local function close_browser()
	close_timer()
	close_window()
end

local function close_browser_and_preview()
	close_browser()
	require("theme_peeper.preview").close()
end

local function strip_row_prefix(line)
	return line:gsub("^%s+", "")
end

local function get_selected_theme(buf)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	if not line or line == "" then
		return nil
	end

	return vim.trim(strip_row_prefix(line))
end

local function browser_is_open()
	return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function preview_theme(theme)
	if not browser_is_open() then
		return
	end

	require("theme_peeper").preview(theme, {
		cache = true,
		enter = false,
	})
end

local function schedule_preview(theme)
	close_timer()

	if not theme then
		return
	end

	state.timer = vim.uv.new_timer()
	state.timer:start(preview_delay_ms, 0, function()
		vim.schedule(function()
			preview_theme(theme)
		end)
	end)
end

local function wrapped_row(row, line_count)
	if row < 1 then
		return line_count
	end

	if row > line_count then
		return 1
	end

	return row
end

local function move_cursor(buf, delta)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_count = vim.api.nvim_buf_line_count(buf)
	local next_row = wrapped_row(cursor[1] + delta, line_count)

	vim.api.nvim_win_set_cursor(0, { next_row, 0 })
	schedule_preview(get_selected_theme(buf))
end

local function display_line(theme)
	return "  " .. theme
end

local function display_lines(themes)
	local lines = {}

	for _, theme in ipairs(themes) do
		table.insert(lines, display_line(theme))
	end

	return lines
end

local function create_buffer(themes)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_name(buf, "Theme Peeper Browser")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines(themes))

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	return buf
end

local function longest_theme_width(themes)
	local width = 0

	for _, theme in ipairs(themes) do
		width = math.max(width, vim.fn.strdisplaywidth(theme))
	end

	return width
end

local function window_width(themes, ui_width)
	local content_width = longest_theme_width(themes) + 4
	local screen_width = math.floor(ui_width * 0.35)
	local max_width = math.min(browser_max_width, math.max(browser_min_width, screen_width))

	return math.min(math.max(browser_min_width, content_width), max_width)
end

local function window_height(theme_count, ui_height)
	local screen_height = math.floor(ui_height * browser_height_ratio)
	local max_height = math.min(browser_max_height, math.max(browser_min_height, screen_height))

	return math.min(theme_count, max_height)
end

local function preview_left_col(ui_width)
	return math.floor((ui_width - browser_preview_width) / 2)
end

local function window_col(width, ui_width)
	local left_of_preview = preview_left_col(ui_width) - width - browser_preview_gap

	return math.max(browser_left_margin, left_of_preview)
end

local function window_config(themes)
	local ui = vim.api.nvim_list_uis()[1]
	local width = window_width(themes, ui.width)
	local height = window_height(#themes, ui.height)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = window_col(width, ui.width),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Theme Peeper ",
		title_pos = "center",
		zindex = browser_zindex,
	}
end

local function open_window(buf, themes)
	return vim.api.nvim_open_win(buf, true, window_config(themes))
end

local function apply_window_options(win)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].cursorline = true
	vim.wo[win].cursorlineopt = "line"
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	vim.wo[win].scrolloff = 3
	vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle,CursorLine:Visual"
end

local function map(buf, lhs, rhs)
	vim.keymap.set("n", lhs, rhs, { buffer = buf })
end

local function set_keymaps(buf)
	map(buf, "j", function()
		move_cursor(buf, 1)
	end)

	map(buf, "k", function()
		move_cursor(buf, -1)
	end)

	map(buf, "<Down>", function()
		move_cursor(buf, 1)
	end)

	map(buf, "<Up>", function()
		move_cursor(buf, -1)
	end)

	map(buf, "<CR>", close_browser)
	map(buf, "q", close_browser_and_preview)
	map(buf, "<Esc>", close_browser_and_preview)
end

function M.open(themes)
	close_browser_and_preview()

	if #themes == 0 then
		vim.notify("No colorschemes found", vim.log.levels.WARN)
		return
	end

	local buf = create_buffer(themes)
	local win = open_window(buf, themes)

	state.win = win
	state.buf = buf

	apply_window_options(win)
	set_keymaps(buf)
	schedule_preview(get_selected_theme(buf))
end

return M
