#!/usr/bin/env lua5.3

local parse = require "parser"
local commands = require "commands"
local check = require "check"
local inspect = require "inspect"
local system = require "system"
local execute = require "execute"

local function tryParse(str, aliases)
	local res, err = parse(str, commands, aliases or {})
	if not res then
		error(err)
	end
	return res
end

local function assertEq(a, b)
	a, b = inspect(a), inspect(b)
	assert(a == b, string.format("%s ~= %s", a, b))
end

local res = tryParse("help")
assertEq(res.cmd, commands.help.exec)

assertEq(execute([["test string"]], system), {"test string"})

assertEq(execute([[write "more string" 'file]], system), {"INS file more string"})

res = tryParse("+ (list 5 3 7)")
assertEq(res.cmd({}, table.unpack(res.args)), {5 + 3 + 7.0})

-- res = tryParse("+ (list 5 3 7)")
-- assertEq(res.args[1](), {"5", "3", "7"})

-- res = tryParse("+ [5 3 7]")
-- assertEq(res.args[1](), {"5", "3", "7"})

-- res = tryParse("onetoten", {onetoten = "+ (range 1 10)"})
-- assertEq(res.cmd({}, table.unpack(res.args)), {55})

-- res = tryParse("read 'test.lua")
-- system.dir = ""
-- assertEq(type(res.cmd(system, table.unpack(res.args))[1]), "string")

-- res = tryParse("help")
-- assertEq(#check(res), 33)

-- res = tryParse("help alias")
-- assertEq(check(res), "oeu")

