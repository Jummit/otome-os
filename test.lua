#!/usr/bin/env lua5.4
local system = require("system")
local inspect = require("inspect")

i = function(a) print(inspect(a)) end

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

	if type(result) ~= "table" then
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

e("equal [5 7 6]", {})
e("equal [6 6]", {6, 6})
e("equal [-5 7.5]", {})
e("equal ['a 7]", {})
e("equal void", {})

e("or [1 2]", {1, 2})
e("or void [1 2] void", {1, 2})
e("or void void", {})

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

e("size [1 2 3]", 3)
e("size void", 0)

e("every 3 [1 2 3 1 2 5 1 3]", {1, 1, 1})
e("every -2 [1 2 3 1 2 5 1 3]", {3, 5, 1, 2})
e("every 'a [1 2 3 1 2 5 1 3]", ERR)
e("every 0 [1 2 3 1 2 5 1 3]", ERR)
e("every void [1 2 3 1 2 5 1 3]", ERR)

-- Generation --
e("range void void", ERR)
e("range -1 3", {-1, 0, 1, 2, 3})
e("range 3 -1", {3, 2, 1, 0, -1})
e("range 0 0", {0})
e("range 'a 3", ERR)
e("range 3 void", ERR)

e("repeat !fun 3", {"a", "a", "a"})
e("repeat !fun -1", ERR)
e("repeat !fun 'a", ERR)
e("repeat !fun void", ERR)

e("void", {})

-- Manipulation --
e("change [1 1 2 3] [1 2] [2 1]", {2, 2, 1, 3})
e("change [1 1 2 3] [1 2] [1]", ERR)
e("change void [1 2] [1]", {})
e("change [!a 1 2 3] [1 2] [2 1]", ERR)

e("remove 1 [1 1 2 3 1]", {2, 3})
e("remove 1 void", {})
e("remove void [1 1 2 3 1]", {1, 1, 2, 3, 1})

e("unique void", {})
e("unique [1 2 3 1 3]", {1, 2, 3})

e("sort [1 -5 -6]", {-6, -5, 1})
e("sort [1 'a -5 -6 '<]", {-5, -6, 1, "<", "a"})

e("trim [1 2 3] 2", {3})
e("trim [1 2 3] -2", {1})
e("trim [1 2 3] -5", {})
e("trim [1 2 3] 0", {1, 2, 3})
e("trim [1 2 3] void", ERR)
e("trim [1 2 3] 'a", ERR)

e("removeat [1 5 -3] [1 2 3 4 5]", {2, 4})
e("removeat [1 'a -3] [1 2 3 4 5]", ERR)
e("removeat [1 5 -3] [1 2]", {2})

e("shuffle [1 2 3]")

-- Strings --
e("characters 'abc1", {"a", "b", "c", 1})
e("characters !fun", ERR)

e("find")

e("split")
e("replace")

e("length")

-- Lists --
e("columns [1 122] [2 3 3] [3 2 1]", {"1   2 3", "122 3 2"})
e("columns void", {})

e("count")
e("combine")
e("splice")
e("join")
e("list")

-- Flow Control --
e("give")
e("when")

-- History --
e("history")
e("undo", {})
e("redo", {})

-- File System --
e("files", {})

e("delete")
e("new")
e("read")

-- System --
e("time")
e("write 'water 'lake", "water")
