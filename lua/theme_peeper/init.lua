local M = {}

local config = {
	capture = {},
	preview = {},
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

function M.peek(theme)
	local capture = require("theme_peeper.capture")
	local preview = require("theme_peeper.preview")

	local captured, err = capture.theme(theme, config.capture)

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	preview.open(captured, config.preview)
end

function M.debug(theme)
	local capture = require("theme_peeper.capture")
	local debug = require("theme_peeper.debug")

	local captured, err = capture.theme(theme, config.capture)

	if not captured then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	debug.open(captured)
end

return M
