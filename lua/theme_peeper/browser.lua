local M = {}

local state = {
	win = nil,
	buf = nil,
	timer = nil,
}

local function close_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end
end

local function close_window()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
	state.buf = nil
end

local function close_all()
	close_timer()
	close_window()
	require("theme_peeper.preview").close()
end

local function selected_theme(buf)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

	if not line or line == "" then
		return nil
	end

	return vim.trim(line)
end

local function schedule_preview(theme)
	close_timer()

	if not theme then
		return
	end

	state.timer = vim.uv.new_timer()

	state.timer:start(120, 0, function()
		vim.schedule(function()
			if not state.win or not vim.api.nvim_win_is_valid(state.win) then
				return
			end

			require("theme_peeper").preview(theme, {
				cache = true,
				enter = false,
			})
		end)
	end)
end

local function move(buf, delta)
	local line_count = vim.api.nvim_buf_line_count(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local next_row = cursor[1] + delta

	if next_row < 1 then
		next_row = line_count
	elseif next_row > line_count then
		next_row = 1
	end

	vim.api.nvim_win_set_cursor(0, { next_row, 0 })
	schedule_preview(selected_theme(buf))
end

function M.open(themes)
	close_all()

	if #themes == 0 then
		vim.notify("No colorschemes found", vim.log.levels.WARN)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, themes)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	local ui = vim.api.nvim_list_uis()[1]
	local width = 36
	local height = math.min(#themes, math.max(10, math.floor(ui.height * 0.7)))

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = 4,
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Themes ",
		title_pos = "center",
		zindex = 90,
	})

	state.win = win
	state.buf = buf

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].cursorline = true
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"

	vim.keymap.set("n", "j", function()
		move(buf, 1)
	end, { buffer = buf })

	vim.keymap.set("n", "k", function()
		move(buf, -1)
	end, { buffer = buf })

	vim.keymap.set("n", "<Down>", function()
		move(buf, 1)
	end, { buffer = buf })

	vim.keymap.set("n", "<Up>", function()
		move(buf, -1)
	end, { buffer = buf })

	vim.keymap.set("n", "<CR>", function()
		close_timer()
		close_window()
	end, { buffer = buf })

	vim.keymap.set("n", "q", close_all, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close_all, { buffer = buf })

	schedule_preview(selected_theme(buf))
end

return M
