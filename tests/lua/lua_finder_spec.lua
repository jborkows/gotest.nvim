local luaCore = require("gotest.lua")
local core = require("gotest.core")

describe("parsing example", function()
	it("test A", function()
		assert(true, "aaaa")
	end)
	it("test B", function()
		assert(true, "bbb")
	end)
	it("test found case", function()
		vim.cmd("e tests/lua/lua_finder_spec.lua")
		local testA = luaCore.find(0, core.TestIdentifier:new("lua/lua_finder_spec", "parsing example test A"))
		assert(testA == 4, "Should found test A")
	end)

	it("test found second case", function()
		vim.cmd("e tests/lua/lua_finder_spec.lua")
		local testB = luaCore.find(0, core.TestIdentifier:new("lua/lua_finder_spec", "parsing example test B"))
		assert(testB == 7, "Should found test B")
	end)

	it("should not found random test", function()
		vim.cmd("e tests/lua/lua_finder_spec.lua")
		local notExistingTest =
		    luaCore.find(0, core.TestIdentifier:new("lua/lua_finder_spec", "parsing example test C"))
		assert(notExistingTest == nil, "Should found test C")
	end)

	it("should find key as same line as function", function()
		vim.cmd("e tests/lua/lua_finder_spec.lua")
		local line = 6
		local column = 1
		local key = luaCore.findTestKey(line, column)
		assert.equals(
			true,
			luaCore.match(core.TestIdentifier:new("lua/lua_finder_spec", "parsing example test A"), key)
		)
	end)
end)
