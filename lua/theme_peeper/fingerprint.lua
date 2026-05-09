local M = {}

local SCHEMA_VERSION = 1

local function sorted_keys(value)
	local keys = {}

	for key in pairs(value) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)

	return keys
end

local function encode_scalar(value, value_type)
	if value == nil then
		return "nil"
	end

	if value_type == "string" then
		return vim.inspect(value)
	end

	if value_type == "number" or value_type == "boolean" then
		return tostring(value)
	end

	return nil
end

local function stable_encode(value)
	local value_type = type(value)
	local scalar = encode_scalar(value, value_type)

	if scalar then
		return scalar
	end

	if value_type ~= "table" then
		return "<" .. value_type .. ">"
	end

	local parts = { "{" }

	for _, key in ipairs(sorted_keys(value)) do
		table.insert(parts, stable_encode(key))
		table.insert(parts, "=")
		table.insert(parts, stable_encode(value[key]))
		table.insert(parts, ";")
	end

	table.insert(parts, "}")

	return table.concat(parts)
end

local function nvim_version()
	local version = vim.version()

	return {
		major = version.major,
		minor = version.minor,
		patch = version.patch,
	}
end

function M.build(theme, opts)
	local identity = require("theme_peeper.state").cache_identity(theme, opts)

	identity.schema = SCHEMA_VERSION
	identity.nvim = nvim_version()

	return identity
end

function M.key(theme, opts)
	local identity = M.build(theme, opts)

	return vim.fn.sha256(stable_encode(identity))
end

return M
