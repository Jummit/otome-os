#!/usr/bin/env lua5.3

local parse = require "parser"
local commands = require "commands"
local inspect = require "inspect"

local function tryParse(str)
	local res, err = parse(str, commands, {})
	if err then
		error(err)
	end
	return res
end

local function assertEq(a, b)
	a, b = inspect(a), inspect(b)
	assert(a == b, string.format("%s ~= %s", a, b))
end

-- local res = tryParse("help")
-- assertEq(res.cmd, commands.help.exec)

-- res = tryParse([["test string"]])
-- assertEq(res.cmd()[1], "test string")

-- res = tryParse([[write "test string" 'file]])
-- assertEq(res.args[1](), {"test string"})

res = tryParse("calc + (list 5 3 7)")
assertEq(res.args[2](), {"5", "3", "7"})