.PHONY: tests tests-ci

tests:
	@nvim --headless -c 'PlenaryBustedDirectory tests' 
tests-ci:
	@~/programs/nvim --headless -c 'PlenaryBustedDirectory tests' 

