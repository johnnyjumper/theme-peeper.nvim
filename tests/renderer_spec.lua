describe("theme_peeper.renderer", function()
	local function captured_theme(name, normal_bg)
		return {
			requested_theme = name,
			colors_name = name,
			normal = {
				fg = "#eeeeee",
				bg = normal_bg,
			},
			normal_float = {
				fg = "#eeeeee",
				bg = normal_bg,
			},
			float_border = {
				fg = "#6699cc",
				bg = normal_bg,
			},
			comment = {
				fg = "#777777",
				italic = true,
			},
			string = {
				fg = "#99cc99",
			},
			func = {
				fg = "#6699cc",
				bold = true,
			},
			keyword = {
				fg = "#cc6666",
			},
			highlights = {},
		}
	end

	local function preview_groups()
		local groups = vim.fn.getcompletion("ThemePeeperPreview", "highlight")
		table.sort(groups)
		return groups
	end

	it("uses stable preview highlight groups across themes", function()
		local renderer = require("theme_peeper.renderer")
		local buf = vim.api.nvim_create_buf(false, true)

		renderer.render({
			buf = buf,
			captured = captured_theme("theme_one", "#101010"),
		})

		local first = preview_groups()

		renderer.render({
			buf = buf,
			captured = captured_theme("theme_two", "#202020"),
		})

		local second = preview_groups()

		assert.are.same(first, second)

		for _, group in ipairs(second) do
			assert.is_nil(group:match("theme_one"))
			assert.is_nil(group:match("theme_two"))
		end
	end)

	it("renders span highlights without line-wide highlight extmarks", function()
		local renderer = require("theme_peeper.renderer")
		local buf = vim.api.nvim_create_buf(false, true)

		renderer.render({
			buf = buf,
			captured = captured_theme("theme_one", "#101010"),
		})

		local namespace = vim.api.nvim_create_namespace("theme-peeper.render")
		local marks = vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })
		local found_keyword = false

		for _, mark in ipairs(marks) do
			local details = mark[4]

			assert.is_nil(details.line_hl_group)

			if details.hl_group == "ThemePeeperPreviewKeyword" then
				found_keyword = true
			end
		end

		assert.is_true(found_keyword)
	end)

	it("renders configured sample lines and spans", function()
		local renderer = require("theme_peeper.renderer")
		local buf = vim.api.nvim_create_buf(false, true)

		renderer.render({
			buf = buf,
			captured = captured_theme("theme_one", "#101010"),
			preview = {
				sample_lines = {
					"package main",
					'println("hello")',
				},
				spans = {
					{ line = 1, word = "package", group = "Keyword" },
					{ line = 2, word = '"hello"', group = "String" },
				},
			},
		})

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

		assert.are.same({
			"package main",
			'println("hello")',
		}, lines)

		local namespace = vim.api.nvim_create_namespace("theme-peeper.render")
		local marks = vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })

		local found_keyword = false
		local found_string = false

		for _, mark in ipairs(marks) do
			local details = mark[4]

			if details.hl_group == "ThemePeeperPreviewKeyword" then
				found_keyword = true
			end

			if details.hl_group == "ThemePeeperPreviewString" then
				found_string = true
			end
		end

		assert.is_true(found_keyword)
		assert.is_true(found_string)
	end)
end)
