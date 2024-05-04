local tableutils = require("gotest.core.tableutils")

local assert = require("luassert.assert")
describe("contains", function()
	it("should return false if table is nil or empty", function()
		assert.equals(false, tableutils.contains(nil, 1))
		assert.equals(false, tableutils.contains({}, 1))
	end)
	it("should return false if table does not contain at least once element", function()
		assert.equals(
			false,
			tableutils.contains({ 1, 2, 3 }, function(elem)
				return elem > 100
			end)
		)
	end)

	it("should return true if table contains at least once element", function()
		assert.equals(
			true,
			tableutils.contains({ 1, 2, 3, 2 }, function(elem)
				return elem == 2
			end)
		)
	end)
end)
