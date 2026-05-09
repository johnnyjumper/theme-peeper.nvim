describe("theme_peeper.state", function()
	after_each(function()
		vim.g.theme_peeper_test_string = nil
		vim.g.theme_peeper_test_number = nil
		vim.g.theme_peeper_test_boolean = nil
		vim.g.theme_peeper_test_table = nil
	end)

	it("captures string, number, and boolean globals", function()
		vim.g.theme_peeper_test_string = "hello"
		vim.g.theme_peeper_test_number = 42
		vim.g.theme_peeper_test_boolean = true

		local state = require("theme_peeper.state")
		local globals = state.get_safe_globals()

		assert.are.equal("hello", globals.theme_peeper_test_string)
		assert.are.equal(42, globals.theme_peeper_test_number)
		assert.are.equal(true, globals.theme_peeper_test_boolean)
	end)

	it("does not capture table globals", function()
		vim.g.theme_peeper_test_table = { nested = true }

		local state = require("theme_peeper.state")
		local globals = state.get_safe_globals()

		assert.is_nil(globals.theme_peeper_test_table)
	end)

	it("creates a capture payload for the child Neovim process", function()
		local state = require("theme_peeper.state")
		local payload = state.capture_payload("theme_peeper_test_global", {})

		assert.are.equal("theme_peeper_test_global", payload.theme)
		assert.is_table(payload.runtime_paths)
		assert.is_table(payload.globals)
		assert.is_boolean(payload.termguicolors)
		assert.is_string(payload.background)
		assert.is_nil(payload.parent_highlights)
	end)

	it("merges explicit globals into the capture payload", function()
		local state = require("theme_peeper.state")

		local payload = state.capture_payload("theme_peeper_test_global", {
			globals = {
				theme_peeper_test_bg = "#123456",
			},
		})

		assert.are.equal("#123456", payload.globals.theme_peeper_test_bg)
	end)
end)
