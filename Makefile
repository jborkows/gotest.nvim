.PHONY: tests tests-ci

tests:
	@nvim --headless -c 'PlenaryBustedDirectory tests' 
tests-ci:
	@~/programs/nvim --headless -u ci_install_deps.vim
	@~/programs/nvim --headless -c 'PlenaryBustedDirectory tests' 

