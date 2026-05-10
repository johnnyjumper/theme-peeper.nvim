local M = {}

local function load_telescope()
	local ok_pickers, pickers = pcall(require, "telescope.pickers")
	local ok_finders, finders = pcall(require, "telescope.finders")
	local ok_actions, telescope_actions = pcall(require, "telescope.actions")
	local ok_action_state, action_state = pcall(require, "telescope.actions.state")
	local ok_config, config = pcall(require, "telescope.config")

	if not (ok_pickers and ok_finders and ok_actions and ok_action_state and ok_config) then
		return nil
	end

	return {
		pickers = pickers,
		finders = finders,
		actions = telescope_actions,
		action_state = action_state,
		config = config,
	}
end

local function telescope_mappings(opts)
	local mappings = require("theme_peeper.config").get().mappings.telescope

	if opts.mappings ~= nil then
		return opts.mappings
	end

	return mappings
end

local function layout_config(opts)
	local max_height = opts.max_height or 12
	local current = vim.deepcopy(opts.layout_config or {})

	current.height = current.height or max_height + 3
	current.width = current.width or 44
	current.prompt_position = current.prompt_position or "top"

	return current
end

local function preview_selected(actions, opts)
	vim.schedule(function()
		local ok, action_state = pcall(require, "telescope.actions.state")

		if not ok then
			return
		end

		local selection = action_state.get_selected_entry()

		if not selection then
			return
		end

		actions.preview(selection.value, {
			cache = true,
			enter = false,
			previewer = "float",
			placement = "below",
			anchor_win = vim.api.nvim_get_current_win(),
		})
	end)
end

local function map_many(map, mode, keys, rhs)
	for _, key in ipairs(keys or {}) do
		map(mode, key, rhs)
	end
end

local function map_selection_movement(map, prompt_bufnr, telescope, actions, opts)
	local mappings = telescope_mappings(opts)

	if mappings == false then
		return
	end

	local function move(action)
		return function()
			action(prompt_bufnr)
			preview_selected(actions, opts)
		end
	end

	map_many(map, "i", mappings.next and mappings.next.insert, move(telescope.actions.move_selection_next))
	map_many(map, "n", mappings.next and mappings.next.normal, move(telescope.actions.move_selection_next))

	map_many(map, "i", mappings.previous and mappings.previous.insert, move(telescope.actions.move_selection_previous))
	map_many(map, "n", mappings.previous and mappings.previous.normal, move(telescope.actions.move_selection_previous))
end

function M.open(actions, opts)
	opts = opts or {}

	local telescope = load_telescope()

	if not telescope then
		vim.notify("Theme Peeper: telescope.nvim is not available", vim.log.levels.ERROR)
		return require("theme_peeper.pickers.builtin").open(actions, {})
	end

	local picker_opts = vim.tbl_deep_extend("force", {}, opts)

	picker_opts.previewer = false
	picker_opts.name = nil
	picker_opts.max_height = nil
	picker_opts.layout_config = layout_config(opts)

	return telescope.pickers
		.new(picker_opts, {
			prompt_title = picker_opts.prompt_title or "Theme Peeper",
			finder = telescope.finders.new_table({
				results = actions.list(),
			}),
			sorter = telescope.config.values.generic_sorter(picker_opts),
			previewer = false,
			attach_mappings = function(prompt_bufnr, map)
				preview_selected(actions, opts)
				map_selection_movement(map, prompt_bufnr, telescope, actions, opts)

				local function confirm()
					local selection = telescope.action_state.get_selected_entry()
					telescope.actions.close(prompt_bufnr)

					if selection then
						actions.confirm(selection.value, {
							cache = true,
							enter = true,
						})
					end
				end

				telescope.actions.select_default:replace(confirm)

				return true
			end,
		})
		:find()
end

return M
