describe("theme_peeper", function()
	after_each(function()
		require("theme_peeper").setup({})
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
end)
