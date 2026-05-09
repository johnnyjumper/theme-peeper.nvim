local M = {}

local groups = {
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

function M.open(captured)
	local lines = {
		"Theme Peeper Debug",
		"",
		"requested_theme = " .. tostring(captured.requested_theme),
		"colors_name     = " .. tostring(captured.colors_name),
		"background      = " .. tostring(captured.background),
		"",
		"Sonokai globals:",
		"",
	}

	append_inspected(lines, "sonokai", captured.sonokai)

	table.insert(lines, "")
	table.insert(lines, "Captured groups:")
	table.insert(lines, "")

	local lookup = {
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

	for _, group in ipairs(groups) do
		append_inspected(lines, group, lookup[group])
	end

	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.bo[buf].filetype = "lua"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	local ui = vim.api.nvim_list_uis()[1]
	local width = 110
	local height = math.min(#lines, 32)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((ui.width - width) / 2),
		row = math.floor((ui.height - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Theme Peeper Debug ",
		title_pos = "center",
	})

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

return M
