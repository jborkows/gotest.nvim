---comment
---@param text string
---@return RunCommand
local function runnerFromText(text)
	return function(command, handler)
		for line in text:gmatch("([^\n]+)") do
			print("Line " .. line .. "...")
			handler.onData(line)
		end
		print("$$$$$$$$$$$$$$$$$$$$$$$")
		handler.onExit()
	end
end

---@class SpyingMarketView
---@field __factory MarkerViewFactory
---@field wasSuccess fun(lineNumber:integer):boolean
---@field wasFailure fun(lineNumber:integer, bufforNumber:integer):boolean

---@return SpyingMarketView
local function spyingMarkerView()
	---@type table<integer>
	local observedSuccesses = {}
	---@type table<Failure>
	local observedFailures = {}
	---@type MarkerView
	local MarkerView = {

		showFailures = function(failures)
			observedFailures = failures
		end,
		showSuccess = function(lines)
			print("Adding " .. vim.inspect(lines))
			observedSuccesses = lines
		end,
	}
	---@type MarkerViewFactory
	local factory = {
		viewFor = function(_, _)
			print("ViewFor is called")
			return MarkerView
		end,
	}

	local tableutils = require("gotest.core.tableutils")
	return {
		__factory = factory,
		wasSuccess = function(lineNumber)
			print("Successes: " .. vim.inspect(observedSuccesses) .. " searching for " .. (lineNumber - 1))
			return tableutils.containsElement(observedSuccesses, lineNumber - 1)
		end,
		wasFailure = function(lineNumber, bufforNumber)
			print(
				"Failures: "
				.. vim.inspect(observedFailures)
				.. " searching for "
				.. (lineNumber - 1)
				.. " in "
				.. bufforNumber
			)
			return tableutils.contains(observedFailures, function(entry)
				---@type Failure
				local elem = entry
				return (elem.buffor_number == bufforNumber) and (elem.line_number == (lineNumber - 1))
			end)
		end,
	}
end

return {
	---setups
	---@param callback fun()
	prepare = function(callback)
		require("gotest").setup()
		callback()
	end,

	---Overrides marker view factory with observable version
	---@param callback fun(spy:SpyingMarketView)
	useMarkerViewSpy = function(callback)
		local view = spyingMarkerView()
		local old = require("gotest.core").__useMarkerView(view.__factory)
		callback(view)
		require("gotest.core").__useMarkerView(old)
	end,
	---overrides runner with text input
	---@param text string
	---@param callback fun()
	useTextRunner = function(text, callback)
		local runner = runnerFromText(text)
		local old = require("gotest.core").__useRunner(runner)
		callback()
		require("gotest.core").__useRunner(old)
	end,
}
