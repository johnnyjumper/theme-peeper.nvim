describe("theme_peeper.capture", function()
	after_each(function()
		vim.g.theme_peeper_test_bg = nil
		vim.g.theme_peeper_test_fg = nil
	end)

	it("captures a test colorscheme in a clean child Neovim", function()
		local capture = require("theme_peeper.capture")

		local captured, err = capture.theme("theme_peeper_test_global", {})

		assert.is_nil(err)
		assert.is_table(captured)

		assert.are.equal("theme_peeper_test_global", captured.requested_theme)
		assert.are.equal("theme_peeper_test_global", captured.colors_name)

		assert.is_table(captured.normal)
		assert.are.equal("#101010", captured.normal.bg)
		assert.are.equal("#eeeeee", captured.normal.fg)
	end)

	it("passes parent globals into the child Neovim", function()
		vim.g.theme_peeper_test_bg = "#123456"
		vim.g.theme_peeper_test_fg = "#abcdef"

		local capture = require("theme_peeper.capture")

		local captured, err = capture.theme("theme_peeper_test_global", {})

		assert.is_nil(err)
		assert.is_table(captured)

		assert.are.equal("#123456", captured.normal.bg)
		assert.are.equal("#abcdef", captured.normal.fg)
	end)

	it("allows explicit globals to override parent globals", function()
		vim.g.theme_peeper_test_bg = "#111111"

		local capture = require("theme_peeper.capture")

		local captured, err = capture.theme("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#222222",
			},
		})

		assert.is_nil(err)
		assert.is_table(captured)

		assert.are.equal("#222222", captured.normal.bg)
	end)

	it("returns an error for a missing colorscheme", function()
		local capture = require("theme_peeper.capture")

		local captured, err = capture.theme("theme_peeper_missing_theme", {})

		assert.is_nil(captured)
		assert.is_string(err)
	end)
end)
