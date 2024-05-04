---comment
---@param text string
---@return RunCommand
local function runnerFromText(text)
	return function(command, handler)
		for line in text:gmatch("([^\n]+)") do
			handler.onData(line)
		end
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
			observedSuccesses = lines
		end,
	}
	---@type MarkerViewFactory
	local factory = {
		viewFor = function(_, _)
			return MarkerView
		end,
	}

	local tableutils = require("gotest.core.tableutils")
	return {
		__factory = factory,
		wasSuccess = function(lineNumber)
			return tableutils.containsElement(observedSuccesses, lineNumber)
		end,
		wasFailure = function(lineNumber, bufforNumber)
			local bufforNumber = bufforNumber or vim.api.nvim_get_current_buf()
			print("Failures: " .. vim.inspect(observedFailures))
			return tableutils.contains(observedFailures, function(entry)
				---@type Failure
				local elem = entry
				return elem.buffor_number == bufforNumber and elem.line_number == lineNumber
			end)
			return found
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
