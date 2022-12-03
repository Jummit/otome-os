#!/usr/bin/env lua5.4
local system = require("system")
local inspect = require("inspect")

local function e(command, result)
	local res, err = system:executeLine(command)
	if not res then
		error(('Error in command "%s": %s'):format(command, err))
	end

	if type(result) == "string" then
		result = { result }
	end

	local a, b = inspect(result or {}), inspect(res)
	if a ~= b then
		print(('Command "%s" has wrong result:\nExpected %s,\ngot %s'):format(command, a, b))
		os.exit(1)
	end
end

e("write 'water 'lake", "water")
e("% [5 7]", "5")
e("% ['a 7]")
e("% void")
e("% [-2 3]", "1")
e("% [2.4 1.7 0.6]", "0.1")
e("* [5 7]", "35")
e("* [-2 3]", "-6")
e("* [2.4 1.7 0.6]", "2.448")
e("+ [5 7]", "35")
e("+ [-2 3]", "-6")
e("+ [2.4 1.7 0.6]", "2.448")
e("- [5 7]", "35")
e("- [-2 3]", "-6")
e("- [2.4 1.7 0.6]", "2.448")
e("/ [5 7]", "35")
e("/ [-2 3]", "-6")
e("/ [2.4 1.7 0.6]", "2.448")
e("/ [5 7]", "35")
e("/ [-2 3]", "-6")
e("/ [2.4 1.7 0.6]", "2.448")
e("> [5 7]", "35")
e("> [-2 3]", "-6")
e("> [2.4 1.7 0.6]", "2.448")
