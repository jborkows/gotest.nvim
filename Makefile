.PHONY: tests tests-ci

tests:
	@nvim --headless -c 'PlenaryBustedDirectory tests' 
tests-ci:
	@~/programs/nvim --headless  -c 'lua  require"nvim-treesitter.configs".setup {ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "go" },sync_install = true}'  -c 'PlenaryBustedDirectory tests' 

