describe("theme_peeper.cache", function()
	before_each(function()
		package.loaded["theme_peeper.cache"] = nil
	end)

	after_each(function()
		vim.g.theme_peeper_test_bg = nil
		vim.g.theme_peeper_test_fg = nil
	end)

	it("returns cached captures for the same theme and options", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		assert.is_nil(cache.get("theme_peeper_test_global", {}))

		cache.set("theme_peeper_test_global", {}, {
			requested_theme = "theme_peeper_test_global",
			normal = {
				fg = "#eeeeee",
				bg = "#101010",
			},
		})

		local cached = cache.get("theme_peeper_test_global", {})

		assert.is_table(cached)
		assert.are.equal("theme_peeper_test_global", cached.requested_theme)
		assert.are.equal("#101010", cached.normal.bg)
	end)

	it("does not expose cached tables by reference", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		cache.set("theme_peeper_test_global", {}, {
			requested_theme = "theme_peeper_test_global",
			normal = {
				bg = "#101010",
			},
		})

		local cached = cache.get("theme_peeper_test_global", {})
		cached.normal.bg = "#ffffff"

		local second = cache.get("theme_peeper_test_global", {})

		assert.are.equal("#101010", second.normal.bg)
	end)

	it("uses explicit globals in the cache key", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		cache.set("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#111111",
			},
		}, {
			requested_theme = "theme_peeper_test_global",
		})

		local cached = cache.get("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#222222",
			},
		})

		assert.is_nil(cached)
	end)

	it("uses safe parent globals in the cache key", function()
		local cache = require("theme_peeper.cache")

		cache.clear()

		vim.g.theme_peeper_test_bg = "#111111"

		cache.set("theme_peeper_test_global", {}, {
			requested_theme = "theme_peeper_test_global",
		})

		vim.g.theme_peeper_test_bg = "#222222"

		local cached = cache.get("theme_peeper_test_global", {})

		assert.is_nil(cached)
	end)

	it("clears entries", function()
		local cache = require("theme_peeper.cache")

		cache.clear()
		cache.set("theme_peeper_test_global", {}, {
			requested_theme = "theme_peeper_test_global",
		})

		assert.are.equal(1, cache.info().entries)

		cache.clear()

		assert.are.equal(0, cache.info().entries)
	end)
end)
