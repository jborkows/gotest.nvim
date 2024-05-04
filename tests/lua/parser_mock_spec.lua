local fixtures = require("gotest.core.fixtures")
local paths = require("gotest.core.paths")

local multilineText = string.format(
	[[
whichkey.lua loaded
Starting...
Scheduling: tests/lua/source_for_parser_mock_spec.lua

========================================
Testing:        %s
Success ||      mock parser lua source  test A
Success ||      mock parser lua source  test B
Fail ||      mock parser lua source  test C

Success:        2
Failed :        1
Errors :        0
Tests Failed. Exit: 1


]],
	paths.relative("tests/lua/source_for_parser_mock_spec.lua")
)
describe("result check", function()
	it("should parse output", function()
		fixtures.prepare(function()
			fixtures.useMarkerViewSpy(function(viewSpy)
				---@type SpyingMarketView
				local spy = viewSpy

				fixtures.useTextRunner(multilineText, function()
					vim.cmd([[ :e tests/lua/source_for_parser_mock_spec.lua]])
					local bufforNumber = vim.api.nvim_get_current_buf()
					require("gotest.core").executeTests()
					assert.equals(true, spy.wasSuccess(2))
					assert.equals(true, spy.wasSuccess(4))
					assert.equals(true, spy.wasFailure(6, bufforNumber))
				end)
			end)
		end)
	end)
end)
