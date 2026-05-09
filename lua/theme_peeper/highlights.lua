local M = {}

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

function M.get_effective(name)
	local raw_id = vim.fn.hlID(name)

	if raw_id == 0 then
		return {}
	end

	local id = vim.fn.synIDtrans(raw_id)
	local hl = {}

	local fg = attr_to_color(id, "fg")
	local bg = attr_to_color(id, "bg")
	local sp = attr_to_color(id, "sp")

	if fg then
		hl.fg = fg
	end

	if bg then
		hl.bg = bg
	end

	if sp then
		hl.sp = sp
	end

	if attr_to_bool(id, "bold") then
		hl.bold = true
	end

	if attr_to_bool(id, "italic") then
		hl.italic = true
	end

	if attr_to_bool(id, "underline") then
		hl.underline = true
	end

	if attr_to_bool(id, "undercurl") then
		hl.undercurl = true
	end

	if attr_to_bool(id, "strikethrough") then
		hl.strikethrough = true
	end

	if attr_to_bool(id, "reverse") then
		hl.reverse = true
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
