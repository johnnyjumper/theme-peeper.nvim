local M = {}

local color_attrs = { "fg", "bg", "sp" }
local boolean_attrs = {
	"bold",
	"italic",
	"underline",
	"undercurl",
	"strikethrough",
	"reverse",
}

local function attr_to_bool(id, attr)
	return vim.fn.synIDattr(id, attr) == "1"
end

local function attr_to_color(id, attr)
	local value = vim.fn.synIDattr(id, attr .. "#")

	if value == nil or value == "" then
		return nil
	end

	return value
end

local function apply_color_attr(hl, id, attr)
	local value = attr_to_color(id, attr)

	if value then
		hl[attr] = value
	end
end

local function apply_boolean_attr(hl, id, attr)
	if attr_to_bool(id, attr) then
		hl[attr] = true
	end
end

local function effective_id(name)
	local raw_id = vim.fn.hlID(name)

	if raw_id == 0 then
		return nil
	end

	return vim.fn.synIDtrans(raw_id)
end

function M.get_effective(name)
	local id = effective_id(name)

	if not id then
		return {}
	end

	local hl = {}

	for _, attr in ipairs(color_attrs) do
		apply_color_attr(hl, id, attr)
	end

	for _, attr in ipairs(boolean_attrs) do
		apply_boolean_attr(hl, id, attr)
	end

	return hl
end

function M.get_all_effective()
	local highlights = {}
	local names = vim.fn.getcompletion("", "highlight")

	for _, name in ipairs(names) do
		local hl = M.get_effective(name)

		if type(hl) == "table" and not vim.tbl_isempty(hl) then
			highlights[name] = hl
		end
	end

	return highlights
end

return M
