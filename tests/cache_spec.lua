describe("theme_peeper.cache", function()
	before_each(function()
		package.loaded["theme_peeper.cache"] = nil
	end)

	it("returns cached captures for the same key", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		local cached, key = cache.get("theme_peeper_test_global", {})
		assert.is_nil(cached)
		assert.is_string(key)

		cache.set(key, {
			requested_theme = "theme_peeper_test_global",
			normal = {
				fg = "#eeeeee",
				bg = "#101010",
			},
		})

		local second = cache.get("theme_peeper_test_global", {})
		assert.is_table(second)
		assert.are.equal("theme_peeper_test_global", second.requested_theme)

		local info = cache.info()

		assert.are.equal(1, info.entries)
		assert.are.equal(1, info.hits)
		assert.are.equal(1, info.misses)
	end)

	it("clears entries and stats", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		local _, key = cache.get("theme_peeper_test_global", {})
		cache.set(key, { requested_theme = "theme_peeper_test_global" })

		cache.clear()

		local info = cache.info()

		assert.are.equal(0, info.entries)
		assert.are.equal(0, info.hits)
		assert.are.equal(0, info.misses)
	end)

	it("changes key when configured theme globals change", function()
		local cache = require("theme_peeper.cache")

		local first = cache.key("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#111111",
			},
		})

		local second = cache.key("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#222222",
			},
		})

		assert.are_not.equal(first, second)
	end)

	it("does not change key for unrelated highlight noise", function()
		local cache = require("theme_peeper.cache")

		local first = cache.key("theme_peeper_test_global", {})

		vim.api.nvim_set_hl(0, "ThemePeeperIrrelevantNoise", {
			fg = "#010203",
		})

		local second = cache.key("theme_peeper_test_global", {})

		assert.are.equal(first, second)
	end)
end)
