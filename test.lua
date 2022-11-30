#!/usr/bin/env lua5.3

local parse = require "parser"
local commands = require "commands"
local inspect = require "inspect"
local system = require "system"
local execute = require "execute"
local copy = require("utils").copy

local function tryParse(str)
	local res, err = parse(str, commands, system.functions)
	if not res then
		error(err)
	end
	return res
end

local function assertEq(a, b, m)
	a, b = inspect(a), inspect(b)
	if a ~= b and m then print("Failure in '"..m.."':") end
	assert(a == b, string.format("%s ~= %s", a, b))
end

local function assertExec(line, result)
	local res, err = execute(line, system)
	if err then error(err) end
	if not res then error(string.format("Command didn't return a value: '%s'", line)) end
	if result then
		assertEq(copy(res), copy(result), line)
	end
end

local function all()
local res = tryParse("describe")
assertEq(res.cmd, commands.describe.exec)
assertExec([["test string"]], {"test string"})
assertExec([[write "more string" 'file]], {"INS file more string"})
assertExec("+ (list 5 3 7)", {"15"})
assertExec("+ [5 3 7]", {"15"})

execute("read 'test.lua", system)

local _, err = execute("describe", system)
assertEq(type(err), "string")

_, err = execute("describe etime", system)
assertEq(type(err), "string")

execute('combine commands (resize ":   " 100) (describe commands', system)
execute("columns 'a 'b", system)
assertExec("arguments 'combine", { "one or more streams to combine"})
assertExec([[run "'test"]], { "test"})
assertExec("time{part = 'day time=-1}", { tostring(os.date("*t").day)})
assertExec("time{ part = 'day time=-1}", { tostring(os.date("*t").day)})
assertExec("- ['5 5]", {"0"})
assertExec("list time{part='year}", {tostring(os.date("*t").year)})
assertExec("function day (time {part='day})", {"FUN day time {part='day}"})
system:execute("FUN day time {part='day}")
assertExec("day", {tostring(os.date("*t").day)})
assertExec("sort day", {tostring(os.date("*t").day)})
assertExec("function help (sort (columns commands (arguments commands) (describe commands)))")
system:execute("FUN help sort (columns commands (arguments commands) (describe commands))")
assertExec("sort help")
-- assertExec('function myjoin{sep = "  "} (join $1 sep)', "")
assertExec("function two (list $1 $2)")
system:execute("FUN two list $1 $2")
assertExec("two 1 2", {"1", "2"})
end
return {
	all = all,
	assertEq = assertEq,
	assertExec = assertExec,
	system = system,
}
