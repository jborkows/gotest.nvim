local tableutils = require("gotest.core.tableutils")

local assert = require("luassert.assert")
describe("contains", function()
	it("should return false if table is nil or empty", function()
		assert.equals(
			false,
			tableutils.contains(nil, function(elem)
				return elem == 1
			end)
		)
		assert.equals(
			false,
			tableutils.contains({}, function(elem)
				return elem == 1
			end)
		)
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
describe("is empty", function()
	it("nil", function()
		assert.equals(true, tableutils.isEmpty(nil))
	end)

	it("{}", function()
		assert.equals(true, tableutils.isEmpty({}))
	end)

	it("some array", function()
		assert.equals(false, tableutils.isEmpty({ 1 }))
	end)
end)

describe("contains element", function()
	it("should return false if table is nil or empty", function()
		assert.equals(false, tableutils.containsElement(nil, 1))
		assert.equals(false, tableutils.containsElement({}, 1))
	end)
	it("should return false if table does not contain at least once element", function()
		assert.equals(false, tableutils.containsElement({ 1, 2, 3 }, 5))
	end)

	it("should return true if table contains at least once element", function()
		assert.equals(true, tableutils.containsElement({ 1, 2, 3, 2 }, 2))
	end)
end)
describe("add", function()
	it("Should return empty list for adding empty lists", function()
		assert.equals(0, table.maxn(tableutils.add(nil, nil)))
		assert.equals(false, tableutils.add(nil, nil) == nil)

		assert.equals(0, table.maxn(tableutils.add({}, nil)))
		assert.equals(false, tableutils.add({}, nil) == nil)

		assert.equals(0, table.maxn(tableutils.add(nil, {})))
		assert.equals(false, tableutils.add(nil, {}) == nil)
	end)

	it("Should return same list if nil is added to something", function()
		local some = { 1, 2, 3 }
		local result = tableutils.add(some, nil)
		assert.equals(3, table.maxn(result))
		assert.equals(true, tableutils.containsElement(result, 1))
		assert.equals(true, tableutils.containsElement(result, 2))
		assert.equals(true, tableutils.containsElement(result, 3))
	end)

	it("Should return same list if something is added to nil", function()
		local some = { 1, 2, 3 }
		local result = tableutils.add(nil, some)
		assert.equals(3, table.maxn(result))
		assert.equals(true, tableutils.containsElement(result, 1))
		assert.equals(true, tableutils.containsElement(result, 2))
		assert.equals(true, tableutils.containsElement(result, 3))
	end)

	it("Should return merged list", function()
		local some = { 4, 5, 0 }
		local other = { 1, 2, 3 }
		local result = tableutils.add(some, other)
		assert.equals(table.maxn(some) + table.maxn(other), table.maxn(result))
		assert.equals(some[1], result[1])
		assert.equals(some[2], result[2])
		assert.equals(some[3], result[3])

		assert.equals(other[1], result[4])
		assert.equals(other[2], result[5])
		assert.equals(other[3], result[6])
	end)
end)
