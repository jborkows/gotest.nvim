local luaCore = require("gotest.lua")
local core = require("gotest.core")

describe("parsing example", function()
	it("should parse output", function()
		local multilineText = [[
whichkey.lua loaded
Starting...Scheduling: tests/state_spec.lua
Scheduling: tests/golang/parser_spec.lua

========================================
Testing:        xxx/projects/gotest.nvim/tests/golang/parser_spec.lua
Success ||      test A
Success ||      test B
Fail ||      test C

Success:        3
Failed :        0
Errors :        0
========================================

========================================
Testing:        xxx/projects/gotest.nvim/tests/state_spec.lua
Fail ||      some error
Success ||	ok


Success:        3
Failed :        1
Errors :        0
========================================
Tests Failed. Exit: 1


]]
		--- ParsingResult[]
		local result = {}
		for line in multilineText:gmatch("([^\n]+)") do
			print(":->" .. line)
		end
	end)
end)
