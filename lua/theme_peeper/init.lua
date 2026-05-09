local M = {}

local config = {
	capture = {},
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

function M.peek(theme)
	package.loaded["theme_peeper.capture"] = nil
	package.loaded["theme_peeper.preview"] = nil

	local capture = require("theme_peeper.capture")
	local preview = require("theme_peeper.preview")

	local captured, err = capture.theme(theme, config.capture)

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	preview.open(captured)
end

return M
