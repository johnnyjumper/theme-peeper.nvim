describe("theme_peeper", function()
	local paths = {}

	local function temp_path()
		local path = vim.fn.tempname() .. ".json"
		table.insert(paths, path)
		return path
	end

	local function read_persisted_theme(path)
		local lines = vim.fn.readfile(path)
		local decoded = vim.json.decode(table.concat(lines, "\n"))

		return decoded.theme
	end

	after_each(function()
		require("theme_peeper").setup({})

		for _, path in ipairs(paths) do
			pcall(vim.fn.delete, path)
		end

		paths = {}
		vim.g.colors_name = nil
		vim.g.theme_peeper_applied_theme = nil
	end)

	it("uses configured apply function when confirming a theme", function()
		require("theme_peeper").setup({
			apply = function(theme)
				vim.g.theme_peeper_applied_theme = theme
			end,
		})

		local ok = require("theme_peeper").confirm("theme_peeper_test_global")

		assert.is_true(ok)
		assert.are.equal("theme_peeper_test_global", vim.g.theme_peeper_applied_theme)
	end)

	it("stores the current theme on first setup when persistence is enabled", function()
		local path = temp_path()

		vim.g.colors_name = "theme_peeper_test_global"

		require("theme_peeper").setup({
			persist = {
				enabled = true,
				path = path,
			},
			apply = function(theme)
				vim.g.theme_peeper_applied_theme = theme
			end,
		})

		assert.are.equal("theme_peeper_test_global", read_persisted_theme(path))
		assert.is_nil(vim.g.theme_peeper_applied_theme)
	end)

	it("restores the persisted theme on setup", function()
		local path = temp_path()

		vim.fn.writefile({
			vim.json.encode({
				theme = "theme_peeper_test_global",
			}),
		}, path)

		require("theme_peeper").setup({
			persist = {
				enabled = true,
				path = path,
			},
			apply = function(theme)
				vim.g.theme_peeper_applied_theme = theme
			end,
		})

		assert.are.equal("theme_peeper_test_global", vim.g.theme_peeper_applied_theme)
	end)

	it("saves confirmed themes when persistence is enabled", function()
		local path = temp_path()

		require("theme_peeper").setup({
			persist = {
				enabled = true,
				path = path,
			},
			apply = function(theme)
				vim.g.theme_peeper_applied_theme = theme
			end,
		})

		local ok = require("theme_peeper").confirm("theme_peeper_test_global")

		assert.is_true(ok)
		assert.are.equal("theme_peeper_test_global", vim.g.theme_peeper_applied_theme)
		assert.are.equal("theme_peeper_test_global", read_persisted_theme(path))
	end)
end)
