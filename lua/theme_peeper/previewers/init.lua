local M = {}

local function notify_error(message)
	vim.notify(tostring(message), vim.log.levels.ERROR)
end

local function selected_previewer(config, opts)
	if opts and opts.previewer ~= nil then
		return opts.previewer
	end

	return config.previewer
end

local function previewer_name(previewer)
	if type(previewer) == "table" then
		return previewer.name or previewer[1] or "float"
	end

	return previewer
end

local function previewer_opts(config, previewer, opts)
	local merged = vim.tbl_deep_extend("force", config.preview or {}, opts or {})

	if type(previewer) == "table" then
		merged = vim.tbl_deep_extend("force", merged, previewer)
		merged.name = nil
		merged[1] = nil
	end

	return merged
end

local function capture_theme(actions, theme, opts)
	local captured, err = actions.capture(theme, {
		cache = opts and opts.cache,
	})

	if not captured then
		return nil, err
	end

	return captured, nil
end

local function preview_with_custom(fn, ctx)
	return fn(ctx)
end

local function preview_with_float(ctx)
	return require("theme_peeper.previewers.float").open(ctx.captured, ctx.opts)
end

function M.preview(actions, theme, opts)
	opts = opts or {}

	local previewer = selected_previewer(actions.config, opts)

	if previewer == false then
		return nil, nil
	end

	local captured, err = capture_theme(actions, theme, opts)

	if not captured then
		notify_error(err)
		return nil, err
	end

	local ctx = {
		theme = theme,
		captured = captured,
		buf = opts.buf,
		win = opts.win,
		opts = previewer_opts(actions.config, previewer, opts),
		actions = actions,
		render = function(render_opts)
			return require("theme_peeper.renderer").render(render_opts)
		end,
	}

	if type(previewer) == "function" then
		return preview_with_custom(previewer, ctx)
	end

	if previewer_name(previewer) ~= "float" then
		notify_error("Theme Peeper previewer not supported: " .. tostring(previewer_name(previewer)))
		return nil, "unsupported previewer"
	end

	return preview_with_float(ctx)
end

function M.close()
	require("theme_peeper.previewers.float").close()
end

return M
