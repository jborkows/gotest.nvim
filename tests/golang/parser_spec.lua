local golang = require("gotest.golang")
local core = require("gotest.core")
local match = require("gotest.golang.query").match

describe("parsing example", function()
	it("should parse output", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.501376864+02:00","Action":"output","Package":"github.com/package/internal/xxx","Test":"TestXX","Output":"Some output"}'
		)
		assert.equals("Some output", parsed.output.message)
		assert.equals(nil, parsed.event)
		assert.equals(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXX"), parsed.output.key)
	end)

	it("should parse run", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"run","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)

		assert.equals(nil, parsed.output)
		assert.equals(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXX"), parsed.event.key)
		assert.equals("run", parsed.event.type)
	end)

	it("should parse pass", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"pass","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)
		assert.equals(nil, parsed.output)
		assert.equals(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXX"), parsed.event.key)
		assert.equals("success", parsed.event.type)
	end)

	it("should parse fail", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)

		assert.equals(nil, parsed.output)
		assert.equals(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXX"), parsed.event.key)
		assert.equals("failure", parsed.event.type)
	end)

	it("should match packages", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		).event.key
		assert.equals(true, match(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXX"), parsed))
		assert.equals(false, match(core.TestIdentifier:new("github.com/package/internal/xxx", "TestXXa"), parsed))
		assert.equals(false, match(core.TestIdentifier:new("github.com/packages/internal/xxx", "TestXX"), parsed))
		assert.equals(true, match(parsed, core.TestIdentifier:new("package/internal/xxx", "TestXX")))
		assert.equals(true, match(parsed, core.TestIdentifier:new("internal/xxx", "TestXX")))
		assert.equals(true, match(parsed, core.TestIdentifier:new("xxx", "TestXX")))
	end)
	--
	it("should omit if no Test field", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"fail","Package":"github.com/package/internal/xxx"}'
		)
		assert.equals(true, parsed.empty)
	end)

	it("should parse anything else", function()
		local parsed = golang.parse(
			'{"Time":"2024-04-08T23:20:07.498829109+02:00","Action":"failaaaa","Package":"github.com/package/internal/xxx","Test":"TestXX"}'
		)

		assert.equals(true, parsed.empty)
	end)
end)
