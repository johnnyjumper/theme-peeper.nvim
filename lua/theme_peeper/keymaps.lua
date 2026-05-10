local M = {}

local function normalize(lhs)
	if lhs == false or lhs == nil then
		return {}
	end

	if type(lhs) == "string" then
		return { lhs }
	end

	if type(lhs) == "table" then
		return lhs
	end

	return {}
end

function M.set(buf, lhs, rhs, opts)
	opts = opts or {}

	for _, key in ipairs(normalize(lhs)) do
		vim.keymap.set(
			"n",
			key,
			rhs,
			vim.tbl_extend("force", {
				buffer = buf,
				nowait = true,
				silent = true,
			}, opts)
		)
	end
end

return M
