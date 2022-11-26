#!/usr/bin/env lua5.3

local parse = require "parser"
local commands = require "commands"
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

local function assertExec(line, result)
	local res, err = execute(line, system)
	if err then error(err) end
	assertEq(res, result)
end

local res = tryParse("describe")
assertEq(res.cmd, commands.describe.exec)
assertExec([["test string"]], {"test string"})
assertExec([[write "more string" 'file]], {"INS file more string"})
assertExec("+ (list 5 3 7)", {5 + 3 + 7.0})
assertExec("+ [5 3 7]", {5 + 3 + 7.0})

system.aliases.onetoten = "+ (range 1 10)"
assertExec("onetoten", {55})

execute("read 'test.lua", system)

local _, err = execute("describe", system)
assertEq(#err, 37)

_, err = execute("describe alias", system)
assertEq(#err, 34)

print(execute('combine commands (resize ":   " 100) (describe commands', system))
