local M = {}

local store = {}
local stats = {
	hits = 0,
	misses = 0,
}

local function count_entries()
	local count = 0

	for _ in pairs(store) do
		count = count + 1
	end

	return count
end

local function stable_json(value)
	return vim.json.encode(value)
end

function M.key(theme, opts)
	local state = require("theme_peeper.state")
	local payload = state.payload(theme, opts)

	return vim.fn.sha256(stable_json(payload))
end

function M.get(theme, opts)
	local key = M.key(theme, opts)
	local cached = store[key]

	if cached then
		stats.hits = stats.hits + 1
		return vim.deepcopy(cached), key
	end

	stats.misses = stats.misses + 1
	return nil, key
end

function M.set(key, captured)
	store[key] = vim.deepcopy(captured)
end

function M.clear()
	store = {}
	stats.hits = 0
	stats.misses = 0
end

function M.info()
	return {
		entries = count_entries(),
		hits = stats.hits,
		misses = stats.misses,
	}
end

return M
