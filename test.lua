#!/usr/bin/env lua5.4
local system = require("system")
local inspect = require("inspect")

local ERR = {}

local function e(command, result)
	local res, err = system:executeLine(command)
	if not result then
		if err then
			print(('Expected command "%s" to succeed, got error:\n%s'):format(
					command, err))
			os.exit(1)
		end
		return
	end

	if err then
		if result == ERR then
			return
		else
			print(('Unexpected error in command "%s":\n%s'):format(command, err))
			os.exit(1)
		end
	end

	if result == ERR then
		print(('Expected command "%s" to fail, but it returned\n%s.'):format(
				command, inspect(res)))
		os.exit(1)
	end

	if type(result) == "string" then
		result = { result }
	end

	for i, v in ipairs(result) do
		result[i] = tostring(v)
	end

	local a, b = inspect(result), inspect(res)
	if a ~= b then
		print(('Command "%s" has wrong result:\nExpected %s,\ngot %s'):format(
				command, a, b))
		os.exit(1)
	end
end

-- System Setup --
system:registerFunction("fun", "'a")

-- Math Commands --
e("% [-5 7.5 4]", "2.5")
e("% ['a 7 'o]", {})
e("% void", {})

e("* [-5 7.5 4]", "-150.0")
e("* ['a 7]", {})
e("* void", {})

e("+ [-5 7.5 4]", "6.5")
e("+ ['a 7]")
e("+ void")

e("- [-5 7.5 4]", "-16.5")
e("- ['a 7]", {})
e("- void", {})

e("/ [-4.8 8 4 'e]", ERR)
e("/ [-4.8 8 4]", "-0.15")
e("/ ['a 7]", {})
e("/ void", {})

-- Comparisons --
e("< [-5 7.5 'e 5]", ERR)
e("< [-5 7.5 5]", {-5, 7.5, 5})
e("< [5 7.5 5]", {})
e("< ['a 7]", {})
e("< void", {})

e("< [5 7.5 6]", {5, 7.5, 6})
e("> [-5 7.5]", {})
e("> ['a 7]", {})
e("> void", {})

-- Help --
e("commands")
e("functions", "fun")

e("arguments !void")
e("arguments !arguments", "!command")
e("arguments !replace", {"text", "old", "new"})
e("arguments !give", {"!command", "*values"})
e("arguments !void !other", ERR)
e("arguments !('a)", ERR)
e("arguments !fun", ERR)

e("describe !void", "Return nothing")
e("describe !fun", "'a")
e("describe 'a", ERR)
e("describe !void !void", ERR)
e("describe !('a)", ERR)

-- List Indices --
e("at [1 2 3] [1 2 3 4 5]", {1, 2, 3})
e("at [-1 -2 1] [1 2 3 4 5]", {5, 4, 1})
e("at ['a] [1 2 3 4 5]", ERR)

-- Manipulation --
e("change [1 1 2 3] [1 2] [2 1]", {2, 2, 1, 3})
e("change [1 1 2 3] [1 2] [1]", ERR)
e("change void [1 2] [1]", {})
e("change [!a 1 2 3] [1 2] [2 1]", ERR)

e("write 'water 'lake", "water")
