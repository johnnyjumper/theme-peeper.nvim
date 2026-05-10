local M = {}

function M.new(config)
	local actions = {
		config = config,
	}

	actions.themes = require("theme_peeper").list()

	function actions.list()
		return require("theme_peeper").list()
	end

	function actions.capture(theme, opts)
		return require("theme_peeper").capture(theme, opts or {})
	end

	function actions.render(opts)
		return require("theme_peeper.renderer").render(opts)
	end

	function actions.preview(theme, opts)
		return require("theme_peeper.previewers").preview(actions, theme, opts or {})
	end

	function actions.apply(theme)
		return require("theme_peeper").apply(theme)
	end

	function actions.confirm(theme, opts)
		return require("theme_peeper").confirm(theme, opts or {})
	end

	function actions.close()
		require("theme_peeper.previewers").close()
	end

	return actions
end

return M
