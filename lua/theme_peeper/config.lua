local M = {}

local function default_apply(theme)
	vim.cmd.colorscheme(theme)
end

local defaults = {
	apply = default_apply,
	capture = {},
	preview = {
		profile = "code",
		max_height = 24,
		zindex = 80,
		border = "rounded",
		placement = "center",
	},
	cache = {
		enabled = true,
	},
	mappings = {
		preview = {
			close = { "q", "<Esc>" },
		},
		telescope = {
			next = {
				insert = { "<Down>", "<C-n>" },
				normal = { "j", "<Down>" },
			},
			previous = {
				insert = { "<Up>", "<C-p>" },
				normal = { "k", "<Up>" },
			},
		},
	},
	picker = "builtin",
	previewer = "float",
	persist = {
		enabled = false,
		path = nil,
	},
	pickers = {
		builtin = {
			max_height = 12,
		},
		snacks = {
			max_height = 12,
			width = 56,
			row = 0.5,
			col = 0.5,
		},
		telescope = {
			max_height = 12,
			width = 56,
		},
	},
}

local current = vim.deepcopy(defaults)

local function normalized_picker(opts)
	if opts.picker == nil then
		return defaults.picker
	end

	return opts.picker
end

local function normalized_previewer(opts)
	if opts.previewer == nil then
		return defaults.previewer
	end

	return opts.previewer
end

local function normalized_persist(opts)
	if opts.persist == true then
		return {
			enabled = true,
			path = nil,
		}
	end

	if opts.persist == false or opts.persist == nil then
		return vim.deepcopy(defaults.persist)
	end

	if type(opts.persist) == "table" then
		return vim.tbl_deep_extend("force", vim.deepcopy(defaults.persist), opts.persist)
	end

	return vim.deepcopy(defaults.persist)
end

function M.setup(opts)
	opts = opts or {}

	current = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
	current.picker = normalized_picker(opts)
	current.previewer = normalized_previewer(opts)
	current.persist = normalized_persist(opts)
end

function M.get()
	return current
end

function M.defaults()
	return vim.deepcopy(defaults)
end

return M
