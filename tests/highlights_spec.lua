describe("theme_peeper.highlights", function()
	before_each(function()
		vim.o.termguicolors = true

		vim.api.nvim_set_hl(0, "ThemePeeperTestBase", {
			fg = "#112233",
			bg = "#445566",
			bold = true,
			italic = true,
		})

		vim.api.nvim_set_hl(0, "ThemePeeperTestLink", {
			link = "ThemePeeperTestBase",
		})
	end)

	it("reads effective foreground and background colors", function()
		local highlights = require("theme_peeper.highlights")
		local hl = highlights.get_effective("ThemePeeperTestBase")

		assert.are.equal("#112233", hl.fg)
		assert.are.equal("#445566", hl.bg)
		assert.are.equal(true, hl.bold)
		assert.are.equal(true, hl.italic)
	end)

	it("resolves linked highlight groups", function()
		local highlights = require("theme_peeper.highlights")
		local hl = highlights.get_effective("ThemePeeperTestLink")

		assert.are.equal("#112233", hl.fg)
		assert.are.equal("#445566", hl.bg)
		assert.are.equal(true, hl.bold)
		assert.are.equal(true, hl.italic)
	end)

	it("returns an empty table for missing highlight groups", function()
		local highlights = require("theme_peeper.highlights")
		local hl = highlights.get_effective("ThemePeeperMissingGroup")

		assert.are.same({}, hl)
	end)

	it("returns a non-empty effective highlight map", function()
		local highlights = require("theme_peeper.highlights")
		local all = highlights.get_all_effective()

		assert.is_table(all)
		assert.is_table(all.Normal)
	end)
end)
