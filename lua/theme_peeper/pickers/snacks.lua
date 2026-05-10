local M = {}

local function snacks_picker()
	if Snacks and Snacks.picker then
		return Snacks.picker
	end

	local ok, snacks = pcall(require, "snacks")

	if ok and snacks.picker then
		return snacks.picker
	end

	return nil
end

local function make_items(actions)
	return vim.tbl_map(function(theme)
		return {
			text = theme,
			theme = theme,
		}
	end, actions.list())
end

local picker_preview_gap = 2

local function resolve_size(value, total, fallback)
	local size = value or fallback

	if type(size) == "number" and size > 0 and size < 1 then
		return math.floor(total * size)
	end

	return size
end

local function centered_col_for_cluster(picker_width, preview_width, ui_width)
	local total_width = picker_width

	if preview_width then
		total_width = total_width + picker_preview_gap + preview_width
	end

	return math.max(0, math.floor((ui_width - total_width) / 2))
end

local function compact_dimensions(opts)
	local ui = vim.api.nvim_list_uis()[1]
	local width = resolve_size(opts.width, ui.width, 56)
	local height = resolve_size(opts.height, ui.height, (opts.max_height or 12) + 4)
	local preview_width = opts.preview_width or 80

	return {
		row = math.floor((ui.height - height) / 2),
		col = centered_col_for_cluster(width, preview_width, ui.width),
		width = width,
		height = height,
	}
end

local function valid_window(win)
	return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function collect_windows(value, wins, seen, depth)
	if depth > 5 then
		return
	end

	if valid_window(value) then
		if not seen[value] then
			seen[value] = true
			table.insert(wins, value)
		end
		return
	end

	if type(value) ~= "table" then
		return
	end

	for _, key in ipairs({ "win", "winid", "id", "window" }) do
		collect_windows(rawget(value, key), wins, seen, depth + 1)
	end

	for _, key in ipairs({ "input", "list", "main", "layout" }) do
		collect_windows(rawget(value, key), wins, seen, depth + 1)
	end
end

local function box_for_window(win)
	local position = vim.api.nvim_win_get_position(win)

	return {
		row = position[1],
		col = position[2],
		width = vim.api.nvim_win_get_width(win),
		height = vim.api.nvim_win_get_height(win),
	}
end

local function merged_box(boxes)
	if #boxes == 0 then
		return nil
	end

	local top = boxes[1].row
	local left = boxes[1].col
	local bottom = boxes[1].row + boxes[1].height
	local right = boxes[1].col + boxes[1].width

	for _, box in ipairs(boxes) do
		top = math.min(top, box.row)
		left = math.min(left, box.col)
		bottom = math.max(bottom, box.row + box.height)
		right = math.max(right, box.col + box.width)
	end

	return {
		row = top,
		col = left,
		width = right - left,
		height = bottom - top,
	}
end

local function runtime_picker_box(active_picker)
	local wins = {}
	local seen = {}

	collect_windows(active_picker, wins, seen, 0)

	local boxes = vim.tbl_map(box_for_window, wins)

	return merged_box(boxes)
end

local function compact_layout(opts)
	local box = compact_dimensions(opts)

	return {
		layout = {
			box = "vertical",
			backdrop = false,
			row = box.row,
			col = box.col,
			width = box.width,
			height = box.height,
			border = opts.border or "rounded",
			title = opts.title or " Theme Peeper ",
			title_pos = "center",
			{ win = "input", height = 1, border = "bottom" },
			{ win = "list", height = opts.max_height or 12, border = "none" },
		},
	}
end

local function uses_compact_layout(opts)
	return opts.layout == nil
end

local function picker_layout(opts)
	if opts.layout then
		return opts.layout
	end

	return compact_layout(opts)
end

local function picker_box(active_picker, opts)
	if uses_compact_layout(opts) then
		return compact_dimensions(opts)
	end

	return runtime_picker_box(active_picker)
end

local function preview_theme(actions, active_picker, item, opts)
	if not item then
		return
	end

	actions.preview(item.theme or item.text, {
		cache = true,
		enter = false,
		previewer = "float",
		placement = "attached",
		anchor_box = picker_box(active_picker, opts),
		width = opts.preview_width,
		max_height = opts.preview_max_height,
		row_offset = 0,
		col_offset = picker_preview_gap,
	})
end

function M.open(actions, opts)
	opts = opts or {}

	local picker = snacks_picker()

	if not picker then
		vim.notify("Theme Peeper: snacks.nvim picker is not available", vim.log.levels.ERROR)
		return require("theme_peeper.pickers.builtin").open(actions, {})
	end

	local confirmed = false
	local picker_opts = vim.tbl_deep_extend("force", {
		title = "Theme Peeper",
		items = make_items(actions),
		format = "text",
		preview = "none",
		layout = picker_layout(opts),
		on_change = function(active_picker, item)
			preview_theme(actions, active_picker, item, opts)
		end,
		confirm = function(active_picker, item)
			confirmed = true
			active_picker:close()

			if not item then
				actions.close()
				return
			end

			actions.confirm(item.theme or item.text, {
				cache = true,
				enter = true,
			})
		end,
		on_close = function()
			if not confirmed then
				actions.close()
			end
		end,
	}, opts or {})

	-- Keep Snacks-native options like `win`, `actions`, `layout`, and `sources`.
	-- Remove only Theme Peeper helper options before passing config to Snacks.
	picker_opts.name = nil
	picker_opts.max_height = nil
	picker_opts.width = nil
	picker_opts.row = nil
	picker_opts.col = nil
	picker_opts.preview_width = nil
	picker_opts.preview_max_height = nil
	picker_opts.previewer = nil

	return picker.pick(picker_opts)
end

return M
