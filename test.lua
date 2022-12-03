#!/usr/bin/env lua5.4
local system = require("system")
local inspect = require("inspect")

local function e(command, result)
	local res, err = system:executeLine(command)
	if not res then
		error(('Error in command "%s": %s'):format(command, err))
	end

	if type(result) == "string" then
		result = {result}
	end

	local a, b = inspect(res), inspect(result)
	if a ~= b then
		print(('Command "%s" has wrong result:\n%s\nis not\n%s'):format(command, a, b))
		os.exit(1)
	end
end

e([[write 'water 'lake]], "water")
