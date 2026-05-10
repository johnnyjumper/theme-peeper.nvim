local M = {}

local state = {
	win = nil,
	buf = nil,
}

local MIN_WIDTH = 20
local MIN_HEIGHT = 1
local SCREEN_BOTTOM_PADDING = 2
local SCREEN_LEFT_PADDING = 2
local SCREEN_RIGHT_PADDING = 2

local function close_window()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		require("theme_peeper.renderer").clear(state.buf, state.win)
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
	state.buf = nil
end

local function valid_window(win)
	return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function window_box(win)
	local position = vim.api.nvim_win_get_position(win)

	return {
		row = position[1],
		col = position[2],
		width = vim.api.nvim_win_get_width(win),
		height = vim.api.nvim_win_get_height(win),
	}
end

local function anchor_box(opts)
	if type(opts.anchor_box) == "table" then
		return opts.anchor_box
	end

	if valid_window(opts.anchor_win) then
		return window_box(opts.anchor_win)
	end

	if valid_window(vim.api.nvim_get_current_win()) then
		return window_box(vim.api.nvim_get_current_win())
	end

	return nil
end

local function clamp(value, min_value, max_value)
	return math.max(min_value, math.min(value, max_value))
end

local function border_size(border)
	if border == nil or border == false or border == "none" then
		return 0
	end

	return 2
end

local function content_size_for_outer(outer_size, border)
	return math.max(MIN_WIDTH, outer_size - border_size(border))
end

local function title_for(captured)
	local renderer = require("theme_peeper.renderer")

	return " " .. renderer.theme_name(captured) .. " "
end

local function wanted_content_height(opts)
	local renderer = require("theme_peeper.renderer")
	local max_height = opts.max_height or 24

	return opts.height or math.min(#renderer.lines(opts), max_height)
end

local function wanted_outer_height(opts)
	return wanted_content_height(opts) + border_size(opts.border)
end

local function wanted_outer_width(opts, anchor)
	if opts.width then
		return opts.width + border_size(opts.border)
	end

	if anchor and anchor.width then
		return anchor.width
	end

	return 80 + border_size(opts.border)
end

local function content_height(opts, available_outer_height)
	local border = border_size(opts.border)
	local wanted = wanted_content_height(opts)

	if not available_outer_height then
		return wanted
	end

	return clamp(wanted, MIN_HEIGHT, math.max(MIN_HEIGHT, available_outer_height - border))
end

local function centered_config(captured, opts)
	local ui = vim.api.nvim_list_uis()[1]
	local width = opts.width or 80
	local height = wanted_content_height(opts)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((ui.width - width) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = opts.border or "rounded",
		title = title_for(captured),
		title_pos = "center",
		zindex = opts.zindex or 80,
	}
end

local function below_fits(anchor, opts, ui)
	local row = anchor.row + anchor.height + (opts.row_offset or 0)
	local available = ui.height - row - SCREEN_BOTTOM_PADDING

	return available >= wanted_outer_height(opts)
end

local function side_choice(anchor, outer_width, opts, ui)
	local gap = opts.col_offset or 0
	local right_col = anchor.col + anchor.width + gap
	local right_available = ui.width - right_col - SCREEN_RIGHT_PADDING
	local left_available = anchor.col - gap - SCREEN_LEFT_PADDING

	if right_available >= outer_width or right_available >= left_available then
		return "right", right_available
	end

	return "left", left_available
end

local function side_col(side, anchor, outer_width, opts)
	local gap = opts.col_offset or 0

	if side == "left" then
		return anchor.col - gap - outer_width
	end

	return anchor.col + anchor.width + gap
end

local function side_config(captured, opts, anchor, ui)
	local border = opts.border or "rounded"
	local outer_width = wanted_outer_width(opts, anchor)
	local outer_height = wanted_outer_height(opts)
	local row = anchor.row + (opts.row_offset or 0)

	local side, available_width = side_choice(anchor, outer_width, opts, ui)
	local available_height = ui.height - row - SCREEN_BOTTOM_PADDING

	local min_outer_width = MIN_WIDTH + border_size(border)
	local min_outer_height = MIN_HEIGHT + border_size(border)

	local final_outer_width = clamp(outer_width, min_outer_width, math.max(min_outer_width, available_width))
	local final_outer_height = clamp(outer_height, min_outer_height, math.max(min_outer_height, available_height))

	local col = side_col(side, anchor, final_outer_width, opts)

	return {
		relative = "editor",
		width = content_size_for_outer(final_outer_width, border),
		height = content_height(vim.tbl_extend("force", opts, { border = border }), final_outer_height),
		col = clamp(
			col,
			SCREEN_LEFT_PADDING,
			math.max(SCREEN_LEFT_PADDING, ui.width - final_outer_width - SCREEN_RIGHT_PADDING)
		),
		row = clamp(row, 0, math.max(0, ui.height - final_outer_height - SCREEN_BOTTOM_PADDING)),
		style = "minimal",
		border = border,
		title = title_for(captured),
		title_pos = "center",
		zindex = opts.zindex or 80,
	}
end

local function below_config(captured, opts, anchor, ui)
	local border = opts.border or "rounded"
	local outer_width = wanted_outer_width(opts, anchor)
	local row = anchor.row + anchor.height + (opts.row_offset or 0)
	local col = anchor.col + (opts.col_offset or 0)
	local available_height = ui.height - row - SCREEN_BOTTOM_PADDING
	local available_width = ui.width - col - SCREEN_RIGHT_PADDING
	local final_outer_width =
		clamp(outer_width, MIN_WIDTH + border_size(border), math.max(MIN_WIDTH + border_size(border), available_width))

	return {
		relative = "editor",
		width = content_size_for_outer(final_outer_width, border),
		height = content_height(vim.tbl_extend("force", opts, { border = border }), available_height),
		col = clamp(col, 0, math.max(0, ui.width - final_outer_width - SCREEN_RIGHT_PADDING)),
		row = clamp(row, 0, math.max(0, ui.height - wanted_outer_height(opts) - SCREEN_BOTTOM_PADDING)),
		style = "minimal",
		border = border,
		title = title_for(captured),
		title_pos = "center",
		zindex = opts.zindex or 80,
	}
end

local function attached_config(captured, opts, anchor)
	local ui = vim.api.nvim_list_uis()[1]

	if below_fits(anchor, opts, ui) then
		return below_config(captured, opts, anchor, ui)
	end

	return side_config(captured, opts, anchor, ui)
end

local function window_config(captured, opts)
	opts = opts or {}

	if opts.placement == "attached" or opts.placement == "below" then
		local anchor = anchor_box(opts)

		if anchor then
			return attached_config(captured, opts, anchor)
		end
	end

	return centered_config(captured, opts)
end

local function create_buffer()
	local buf = vim.api.nvim_create_buf(false, true)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false

	return buf
end

local function open_window(buf, captured, opts)
	local enter = opts == nil or opts.enter ~= false

	return vim.api.nvim_open_win(buf, enter, window_config(captured, opts or {}))
end

local function apply_window_options(win)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	vim.wo[win].list = false
	vim.wo[win].spell = false
	vim.wo[win].colorcolumn = ""
	vim.wo[win].cursorline = false
	vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle"
end

local function preview_mappings(opts)
	if opts and opts.mappings ~= nil then
		return opts.mappings
	end

	return require("theme_peeper.config").get().mappings.preview
end

local function set_keymaps(buf, opts)
	local mappings = preview_mappings(opts)

	if mappings == false then
		return
	end

	require("theme_peeper.keymaps").set(buf, mappings.close, close_window, {
		desc = "Close theme preview",
	})
end

function M.open(captured, opts)
	close_window()

	local buf = create_buffer()
	local win = open_window(buf, captured, opts or {})

	state.buf = buf
	state.win = win

	apply_window_options(win)
	require("theme_peeper.renderer").render({
		buf = buf,
		win = win,
		captured = captured,
		preview = opts or {},
	})
	set_keymaps(buf, opts or {})

	return buf, win
end

function M.close()
	close_window()
end

return M
