local M = {}

local profiles = {
	code = {
		lines = {
			"local function create_user(input)",
			'  local name = input.name or "Johnny"',
			"",
			"  if name == nil then",
			'    error("missing name")',
			"  end",
			"",
			"  return {",
			"    id = 1,",
			"    name = name,",
			"    active = true,",
			"  }",
			"end",
			"",
			"-- Diagnostics",
			"-- Error: type mismatch",
			"-- Warning: unused variable",
			"-- Hint: extract function",
			"",
			"Normal  Comment  String  Function  Keyword",
			"Visual  Search   CursorLine  Pmenu  FloatBorder",
		},
		spans = {
			{ line = 1, word = "local", group = "Keyword" },
			{ line = 1, word = "function", group = "Keyword" },
			{ line = 1, word = "create_user", group = "Function" },
			{ line = 2, word = "local", group = "Keyword" },
			{ line = 2, word = "name", group = "Identifier" },
			{ line = 2, word = '"Johnny"', group = "String" },
			{ line = 4, word = "if", group = "Keyword" },
			{ line = 4, word = "nil", group = "Constant" },
			{ line = 4, word = "then", group = "Keyword" },
			{ line = 5, word = "error", group = "Function" },
			{ line = 5, word = '"missing name"', group = "String" },
			{ line = 6, word = "end", group = "Keyword" },
			{ line = 8, word = "return", group = "Keyword" },
			{ line = 9, word = "id", group = "Identifier" },
			{ line = 10, word = "name", group = "Identifier" },
			{ line = 11, word = "active", group = "Identifier" },
			{ line = 11, word = "true", group = "Boolean" },
			{ line = 13, word = "end", group = "Keyword" },
			{ line = 15, word = "-- Diagnostics", group = "Comment" },
			{ line = 16, word = "-- Error: type mismatch", group = "DiagnosticError" },
			{ line = 17, word = "-- Warning: unused variable", group = "DiagnosticWarn" },
			{ line = 18, word = "-- Hint: extract function", group = "DiagnosticHint" },
			{ line = 20, word = "Normal", group = "Normal" },
			{ line = 20, word = "Comment", group = "Comment" },
			{ line = 20, word = "String", group = "String" },
			{ line = 20, word = "Function", group = "Function" },
			{ line = 20, word = "Keyword", group = "Keyword" },
			{ line = 21, word = "Visual", group = "Visual" },
			{ line = 21, word = "Search", group = "Search" },
			{ line = 21, word = "CursorLine", group = "CursorLine" },
			{ line = 21, word = "Pmenu", group = "Pmenu" },
			{ line = 21, word = "FloatBorder", group = "FloatBorder" },
		},
	},

	diagnostics = {
		lines = {
			"-- Diagnostics",
			"Error: type mismatch",
			"Warning: unused variable",
			"Info: inferred return type",
			"Hint: extract function",
			"",
			"local value = maybe_nil.field",
			"return value",
		},
		spans = {
			{ line = 1, word = "-- Diagnostics", group = "Comment" },
			{ line = 2, word = "Error: type mismatch", group = "DiagnosticError" },
			{ line = 3, word = "Warning: unused variable", group = "DiagnosticWarn" },
			{ line = 4, word = "Info: inferred return type", group = "DiagnosticInfo" },
			{ line = 5, word = "Hint: extract function", group = "DiagnosticHint" },
			{ line = 7, word = "local", group = "Keyword" },
			{ line = 7, word = "value", group = "Identifier" },
			{ line = 8, word = "return", group = "Keyword" },
		},
	},

	ui = {
		lines = {
			"Normal  NormalFloat  FloatBorder  FloatTitle",
			"CursorLine  Visual  Search  IncSearch",
			"Pmenu  PmenuSel  StatusLine  WinSeparator",
			"LineNr  SignColumn  Folded  EndOfBuffer",
		},
		spans = {
			{ line = 1, word = "Normal", group = "Normal" },
			{ line = 1, word = "NormalFloat", group = "NormalFloat" },
			{ line = 1, word = "FloatBorder", group = "FloatBorder" },
			{ line = 1, word = "FloatTitle", group = "FloatTitle" },
			{ line = 2, word = "CursorLine", group = "CursorLine" },
			{ line = 2, word = "Visual", group = "Visual" },
			{ line = 2, word = "Search", group = "Search" },
			{ line = 2, word = "IncSearch", group = "IncSearch" },
			{ line = 3, word = "Pmenu", group = "Pmenu" },
			{ line = 3, word = "PmenuSel", group = "PmenuSel" },
			{ line = 3, word = "StatusLine", group = "StatusLine" },
			{ line = 3, word = "WinSeparator", group = "WinSeparator" },
			{ line = 4, word = "LineNr", group = "LineNr" },
			{ line = 4, word = "SignColumn", group = "SignColumn" },
			{ line = 4, word = "Folded", group = "Folded" },
			{ line = 4, word = "EndOfBuffer", group = "EndOfBuffer" },
		},
	},

	minimal = {
		lines = {
			"Normal  Comment  String  Function  Keyword",
			"Visual  Search  CursorLine  FloatBorder",
		},
		spans = {
			{ line = 1, word = "Normal", group = "Normal" },
			{ line = 1, word = "Comment", group = "Comment" },
			{ line = 1, word = "String", group = "String" },
			{ line = 1, word = "Function", group = "Function" },
			{ line = 1, word = "Keyword", group = "Keyword" },
			{ line = 2, word = "Visual", group = "Visual" },
			{ line = 2, word = "Search", group = "Search" },
			{ line = 2, word = "CursorLine", group = "CursorLine" },
			{ line = 2, word = "FloatBorder", group = "FloatBorder" },
		},
	},
}

local function profile(name)
	return vim.deepcopy(profiles[name or "code"] or profiles.code)
end

function M.resolve(opts)
	opts = opts or {}

	local sample = profile(opts.profile)

	if type(opts.sample_lines) == "table" then
		sample.lines = vim.deepcopy(opts.sample_lines)
	end

	if type(opts.spans) == "table" then
		sample.spans = vim.deepcopy(opts.spans)
	end

	if type(opts.groups) == "table" then
		sample.groups = vim.deepcopy(opts.groups)
	end

	return sample
end

return M
