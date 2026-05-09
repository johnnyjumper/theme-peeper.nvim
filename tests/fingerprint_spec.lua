describe("theme_peeper.fingerprint", function()
	after_each(function()
		vim.g.theme_peeper_test_bg = nil
		vim.g.theme_peeper_test_fg = nil
	end)

	it("builds a fingerprint for a target theme", function()
		local fingerprint = require("theme_peeper.fingerprint")
		local value = fingerprint.build("theme_peeper_test_global", {})

		assert.are.equal("theme_peeper_test_global", value.theme)
		assert.is_number(value.schema)
		assert.is_table(value.runtime_paths)
		assert.is_table(value.globals)
		assert.is_table(value.nvim)
	end)

	it("does not include parent highlights", function()
		local fingerprint = require("theme_peeper.fingerprint")
		local value = fingerprint.build("theme_peeper_test_global", {})

		assert.is_nil(value.parent_highlights)
	end)

	it("produces stable keys for identical inputs", function()
		local fingerprint = require("theme_peeper.fingerprint")

		local first = fingerprint.key("theme_peeper_test_global", {})
		local second = fingerprint.key("theme_peeper_test_global", {})

		assert.are.equal(first, second)
	end)

	it("changes key when automatically captured safe globals change", function()
		local fingerprint = require("theme_peeper.fingerprint")

		vim.g.theme_peeper_test_bg = "#111111"
		local first = fingerprint.key("theme_peeper_test_global", {})

		vim.g.theme_peeper_test_bg = "#222222"
		local second = fingerprint.key("theme_peeper_test_global", {})

		assert.are_not.equal(first, second)
	end)

	it("changes key when explicit globals change", function()
		local fingerprint = require("theme_peeper.fingerprint")

		local first = fingerprint.key("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#111111",
			},
		})

		local second = fingerprint.key("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#222222",
			},
		})

		assert.are_not.equal(first, second)
	end)

	it("does not change key for unrelated highlight noise", function()
		local fingerprint = require("theme_peeper.fingerprint")

		local first = fingerprint.key("theme_peeper_test_global", {})

		vim.api.nvim_set_hl(0, "ThemePeeperIrrelevantNoise", {
			fg = "#010203",
		})

		local second = fingerprint.key("theme_peeper_test_global", {})

		assert.are.equal(first, second)
	end)
end)
