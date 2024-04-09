local parser = require("gotest.parser")

describe("parsing example", function()
	it("should parse output", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.501376864+02:00","Action":"output","Package":"github.com/package/internal/xxx","Test":"TestXX","Output":"Some output"}'
		)
		assert.equals("Some output", parsed.action.output)
		assert.equals("output", parsed.action.Type)
		assert.equals("github.com/package/internal/xxx", parsed.package)
		assert.equals("TestXX", parsed.testName)
	end)

	it("should parse run", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"run","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(nil, parsed.action.output)
		assert.equals("run", parsed.action.Type)
		assert.equals("github.com/package/internal/xxx", parsed.package)
		assert.equals("TestXX", parsed.testName)
	end)

	it("should parse pass", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"pass","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(nil, parsed.action.output)
		assert.equals("pass", parsed.action.Type)
		assert.equals("github.com/package/internal/xxx", parsed.package)
		assert.equals("TestXX", parsed.testName)
	end)

	it("should parse fail", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(nil, parsed.action.output)
		assert.equals("fail", parsed.action.Type)
		assert.equals("github.com/package/internal/xxx", parsed.package)
		assert.equals("TestXX", parsed.testName)
	end)

	it("should match packages", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(true, parsed.match("github.com/package/internal/xxx", "TestXX"))
		assert.equals(false, parsed.match("github.com/package/internal/xxx", "TestXXa"))
		assert.equals(false, parsed.match("github.com/packages/internal/xxx", "TestXX"))

		assert.equals(true, parsed.match("package/internal/xxx", "TestXX"))
		assert.equals(true, parsed.match("internal/xxx", "TestXX"))
		assert.equals(true, parsed.match("xxx", "TestXX"))
	end)

	it("should omit if no Test field", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx"}'
		)
		assert.equals(nil, parsed)
	end)

	it("should parse anything else", function()
		local parsed = parser.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"failaaaa","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(nil, parsed)
	end)
end)
