local M = {}

local store = {}

local function sorted_keys(tbl)
	local keys = {}

	for key in pairs(tbl or {}) do
		table.insert(keys, key)
	end

	table.sort(keys, function(left, right)
		return tostring(left) < tostring(right)
	end)

	return keys
end

local function encode_value(value)
	local value_type = type(value)

	if value == nil then
		return "nil"
	end

	if value_type == "string" then
		return string.format("%q", value)
	end

	if value_type == "number" or value_type == "boolean" then
		return tostring(value)
	end

	if value_type ~= "table" then
		return value_type .. ":" .. tostring(value)
	end

	local parts = {}

	for _, key in ipairs(sorted_keys(value)) do
		table.insert(parts, encode_value(key) .. "=" .. encode_value(value[key]))
	end

	return "{" .. table.concat(parts, ",") .. "}"
end

local function cache_key(theme, opts)
	local payload = require("theme_peeper.state").capture_payload(theme, opts)

	return encode_value(payload)
end

local function count_entries()
	local count = 0

	for _ in pairs(store) do
		count = count + 1
	end

	return count
end

function M.get(theme, opts)
	local cached = store[cache_key(theme, opts)]

	if not cached then
		return nil
	end

	return vim.deepcopy(cached)
end

function M.set(theme, opts, captured)
	store[cache_key(theme, opts)] = vim.deepcopy(captured)
end

function M.clear()
	store = {}
end

function M.info()
	return {
		entries = count_entries(),
	}
end

return M
