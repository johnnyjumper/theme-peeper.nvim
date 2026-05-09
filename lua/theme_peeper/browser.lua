local M = {}

local browser_width = 36
local browser_min_height = 10
local browser_height_ratio = 0.7
local browser_left_margin = 4
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

local function get_selected_theme(buf)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	if not line or line == "" then
		return nil
	end

	return vim.trim(line)
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

local function create_buffer(themes)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, themes)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	return buf
end

local function window_height(theme_count, ui_height)
	local max_height = math.floor(ui_height * browser_height_ratio)

	return math.min(theme_count, math.max(browser_min_height, max_height))
end

local function window_config(theme_count)
	local ui = vim.api.nvim_list_uis()[1]
	local height = window_height(theme_count, ui.height)

	return {
		relative = "editor",
		width = browser_width,
		height = height,
		col = browser_left_margin,
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Themes ",
		title_pos = "center",
		zindex = browser_zindex,
	}
end

local function open_window(buf, theme_count)
	return vim.api.nvim_open_win(buf, true, window_config(theme_count))
end

local function apply_window_options(win)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].cursorline = true
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
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
	local win = open_window(buf, #themes)

	state.win = win
	state.buf = buf

	apply_window_options(win)
	set_keymaps(buf)
	schedule_preview(get_selected_theme(buf))
end

return M
