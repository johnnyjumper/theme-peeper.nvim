local M = {}

local defaults = {
	enabled = false,
	path = nil,
}

local function is_theme(theme)
	return type(theme) == "string" and theme ~= ""
end

function M.default_path()
	return vim.fn.stdpath("data") .. "/theme-peeper/theme.json"
end

local function normalized(opts)
	if opts == true then
		opts = {
			enabled = true,
		}
	end

	if opts == false or opts == nil then
		opts = {}
	end

	if type(opts) ~= "table" then
		opts = {}
	end

	local persist = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)

	if persist.enabled and (persist.path == nil or persist.path == "") then
		persist.path = M.default_path()
	end

	return persist
end

function M.current()
	return vim.g.colors_name
end

function M.read(opts)
	local persist = normalized(opts)

	if not persist.enabled then
		return nil, nil
	end

	if vim.fn.filereadable(persist.path) ~= 1 then
		return nil, nil
	end

	local ok_read, lines = pcall(vim.fn.readfile, persist.path)

	if not ok_read then
		return nil, "Failed to read persisted theme: " .. persist.path
	end

	local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))

	if not ok_decode or type(decoded) ~= "table" then
		return nil, "Failed to decode persisted theme: " .. persist.path
	end

	if not is_theme(decoded.theme) then
		return nil, nil
	end

	return decoded.theme, nil
end

function M.write(theme, opts)
	local persist = normalized(opts)

	if not persist.enabled or not is_theme(theme) then
		return true, nil
	end

	local dir = vim.fn.fnamemodify(persist.path, ":h")
	local ok_mkdir, mkdir_err = pcall(vim.fn.mkdir, dir, "p")

	if not ok_mkdir then
		return false, mkdir_err
	end

	local ok_write, write_err = pcall(vim.fn.writefile, {
		vim.json.encode({
			theme = theme,
		}),
	}, persist.path)

	if not ok_write then
		return false, write_err
	end

	return true, nil
end

function M.sync(opts, apply)
	local persist = normalized(opts)

	if not persist.enabled then
		return true, nil
	end

	local persisted_theme, read_err = M.read(persist)

	if read_err then
		return false, read_err
	end

	if is_theme(persisted_theme) then
		return apply(persisted_theme), nil
	end

	return M.write(M.current(), persist)
end

return M
