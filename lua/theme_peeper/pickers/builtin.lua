local M = {}

local function notify_no_themes()
	vim.notify("No colorschemes found", vim.log.levels.WARN)
end

function M.open(actions, opts)
	opts = opts or {}

	local themes = actions.list()

	if #themes == 0 then
		notify_no_themes()
		return
	end

	vim.ui.select(themes, {
		prompt = opts.prompt or "Select colorscheme",
	}, function(theme)
		if not theme then
			return
		end

		actions.confirm(theme, {
			cache = true,
			enter = true,
		})
	end)
end

return M
