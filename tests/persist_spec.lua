describe("theme_peeper.persist", function()
	local paths = {}

	local function temp_path()
		local path = vim.fn.tempname() .. ".json"
		table.insert(paths, path)
		return path
	end

	after_each(function()
		for _, path in ipairs(paths) do
			pcall(vim.fn.delete, path)
		end

		paths = {}
		vim.g.colors_name = nil
	end)

	it("is disabled by default", function()
		local defaults = require("theme_peeper.config").defaults()

		assert.is_false(defaults.persist.enabled)
	end)

	it("does not write when disabled", function()
		local persist = require("theme_peeper.persist")
		local path = temp_path()

		local ok, err = persist.write("theme_peeper_test_global", {
			enabled = false,
			path = path,
		})

		assert.is_true(ok)
		assert.is_nil(err)
		assert.are.equal(0, vim.fn.filereadable(path))
	end)

	it("writes and reads a persisted theme", function()
		local persist = require("theme_peeper.persist")
		local path = temp_path()

		local ok, err = persist.write("theme_peeper_test_global", {
			enabled = true,
			path = path,
		})

		assert.is_true(ok)
		assert.is_nil(err)

		local theme, read_err = persist.read({
			enabled = true,
			path = path,
		})

		assert.is_nil(read_err)
		assert.are.equal("theme_peeper_test_global", theme)
	end)

	it("stores the current theme when no persisted theme exists", function()
		local persist = require("theme_peeper.persist")
		local path = temp_path()

		vim.g.colors_name = "theme_peeper_test_global"

		local ok, err = persist.sync({
			enabled = true,
			path = path,
		}, function()
			error("apply should not run without a persisted theme")
		end)

		assert.is_true(ok)
		assert.is_nil(err)

		local theme = persist.read({
			enabled = true,
			path = path,
		})

		assert.are.equal("theme_peeper_test_global", theme)
	end)

	it("applies a persisted theme when one exists", function()
		local persist = require("theme_peeper.persist")
		local path = temp_path()
		local applied = nil

		persist.write("theme_peeper_test_global", {
			enabled = true,
			path = path,
		})

		local ok, err = persist.sync({
			enabled = true,
			path = path,
		}, function(theme)
			applied = theme
			return true
		end)

		assert.is_true(ok)
		assert.is_nil(err)
		assert.are.equal("theme_peeper_test_global", applied)
	end)
end)
