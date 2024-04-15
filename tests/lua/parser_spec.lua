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
		local results = {}
		local parser = luaCore.parser("xxx/projects/gotest.nvim/tests/")
		for line in multilineText:gmatch("([^\n]+)") do
			local parsed = parser.parse(line)
			table.insert(results, parsed)
		end

		local expected = {
			core.started(),
			core.success(core.TestIdentifier:new("golang/parser_spec", "test A")),
			core.success(core.TestIdentifier:new("golang/parser_spec", "test B")),
			core.failure(core.TestIdentifier:new("golang/parser_spec", "test C")),
			core.failure(core.TestIdentifier:new("state_spec", "some error")),
			core.success(core.TestIdentifier:new("state_spec", "ok")),
		}
		assert(true, table.maxn(results) >= table.maxn(expected))

		-- print(vim.inspect(results))
		local parsedIndex = 1
		for i, expect in pairs(expected) do
			for j = parsedIndex, table.maxn(results) do
				local parsed = results[parsedIndex].event
				if parsed == nil then
					--NOP
				else
					if parsed == expect then
						goto finish
					end

					assert(false, "Should not come here")
				end
			end
			::finish::
		end
	end)
end)
