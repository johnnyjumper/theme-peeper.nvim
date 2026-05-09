NVIM ?= nvim
TEST_DEPS_DIR := .tests
PLENARY_DIR := $(TEST_DEPS_DIR)/plenary.nvim

.PHONY: test test-deps clean-test-deps

test: test-deps
	$(NVIM) --headless -u tests/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('tests', { minimal_init = 'tests/minimal_init.lua' })" \
		-c "qa!"

test-deps:
	@if [ ! -d "$(PLENARY_DIR)" ]; then \
		git clone --filter=blob:none https://github.com/nvim-lua/plenary.nvim.git "$(PLENARY_DIR)"; \
	fi

clean-test-deps:
	rm -rf "$(TEST_DEPS_DIR)"
