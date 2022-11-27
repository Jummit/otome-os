--------------------
--    Commands    --
--------------------

local utils = require("utils")
local describeArgs = require "describeArgs"
local keys, escape, map, join = utils.keys, utils.escape, utils.map, utils.join
local execute = require "execute"

local commands = {}
commands.commands = {desc = "Show a list of available commands",
	exec = function(_)
	  return keys(commands)
	end
}
commands.replace = {desc = "Find and replace inside the stream",
	args = {"text", "old", "new"},
	exec = function(_, inp, from, to)
	  return map(inp, function(v)
	    return v:gsub(escape(from[1]), to[1])
	  end)
	end
}
commands.combine = {desc = "Combine multiple streams",
	args = "streams to combine", exec = function(_, ...)
	  local r = {}
	  local streams = {...}
	  for i = 1, math.min(table.unpack(map(streams, function(e) return #e end))) do
	    table.insert(r, table.concat(map(streams, function(e) return e[i] end), " "))
	  end
	  return r
	end
}
commands.sort = {desc = "Sort the stream",
	args = {"words"}, exec = function(_, stream)
    table.sort(stream)
    return stream
	end
}
-- {{"a", "abc"}, {"test", "longer"}}
-- a   test
-- abc longer
commands.columns = {desc = "Combine multiple streams as columns",
	args = "streams", exec = function(_, ...)
    local streams = map({...}, function(s)
      local max = 0
      for _, e in ipairs(s) do
        max = math.max(#e, max)
      end
      return map(s, function(e)
        return e..string.rep(" ", max - #e)
      end)
    end)
    local r = {}
    for i = 1, 100 do
      local sub = {}
      for _, s in ipairs(streams) do
        if not s[i] then return r end
        table.insert(sub, s[i])
      end
      table.insert(r, table.concat(sub, " "))
    end
	end
}
commands.splice = {desc = "",
	args = "streams", exec = function(_, ...)
	  local r = {}
	  local streams = {...}
	  for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
	    for _, stream in ipairs(streams) do
	      table.insert(r, stream[i])
	    end
	  end
	  return r
	end
}
commands.read = {desc = "Show the content of the given files",
	args = "files", exec = function(ctx, names)
	  return map(names, function(n) return ctx:read(n) end)
	end
}
commands.run = {desc = "Run the given lines of code",
	args = "lines", exec = function(ctx, lines)
    return map(lines, function(l)
      local output, err = execute(l, ctx)
      if not output then return err end
      return table.concat(output, "\n")
    end)
	end
}
commands.split = {desc = "Split the strings",
	args = "strings", exec = function(_, strings)
    local r = {}
    for _, str in ipairs(strings) do
      for elem in str:gmatch("[^\n]+") do
        table.insert(r, elem)
      end
    end
    return r
	end
}
commands.files = {desc = "Show the available files", exec = function(ctx)
  return ctx:getFiles()
end}
commands.new = {desc = "Create the given files", args = "file names", exec = function(_, names)
  return map(names, function(n)
    return "NEW "..n
  end)
end}
commands.delete = {desc = "Delete the given files", args = "files", exec = function(_, names)
  return map(names, function(n)
    return "DEL "..n
  end)
end}
commands.resize = {desc = "Extend the stream", args = {"amount", "stream"}, exec = function(_, stream, count)
  local o = {}
  stream = stream
  for i = 1, tonumber(count[1]) do
    o[i] = stream[i] or stream[#stream]
  end
  return o
end}
commands.time = {desc = "Show the time", exec = function(_)
  return { os.time() }
end}
commands.list = {desc = "Create a list", args = "elements", exec = function(_, ...)
  local l = {}
  for _, arg in ipairs(table.pack(...)) do
    for _, val in ipairs(arg) do
      table.insert(l, val)
    end
  end
  return l
end}
commands.write = {desc = "Write something into a file", args = {"text", "files"}, exec = function(_, text, file)
  return {"INS "..file[1].." "..table.concat(text, "\n")}
end}
commands.range = {desc = "Generate a sequence of numbers", args = {"from", "to", {"step"}}, exec = function(_, from, to)
  local t = {}
  for i = tonumber(from[1]), tonumber(to[1]) do
    table.insert(t, i)
  end
  return t
end}
commands.history = {desc = "Show the history", exec = function(ctx)
  return map(join(ctx.history.history, ctx.history.reverts), function(h) return h.name end)
end}
commands.undo = {desc = "Undo an operation", args = {{"number of operations"}}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local undoAction = ctx.history:undo()
    if not undoAction then break end
    table.insert(actions, undoAction.name)
  end
  return actions
end}
commands.redo = {desc = "Redo an operation", args = {{"number of operations"}}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local toRedo = ctx.history:redo()
    if not toRedo then break end
    local name = toRedo.name:gsub("Undid ", "")
    table.insert(actions, name.." again")
  end
  return actions
end}
commands.describe = {desc = "Show help for the given commands", args = "commands", exec = function(ctx, helpFor)
  return map(helpFor, function(c)
    if ctx.aliases[c] then
      return ctx.aliases[c]
    end
    return commands[c].desc
  end)
end}
commands.arguments = {desc = "Show args of a command", args = "commands", exec = function(_, helpFor)
  return map(helpFor, function(c)
    return describeArgs(commands[c].args).str
  end)
end}
commands.alias = {desc = "Add a command alias", args = {"stream of commands and their aliases"},
  exec = function(ctx, aliases)
    for num = 1, #aliases, 2 do
      ctx.aliases[aliases[num]] = aliases[num + 1]
    end
    return {}
  end
}
commands.aliases = {desc = "Get a list of aliases", exec = function(ctx)
  return keys(ctx.aliases)
end}
commands.join = {desc = "Join a list of words", args = {"words", {"a separator"}}, exec = function(_, words, sep)
	return {table.concat(words, (sep or {" "})[1])}
end}

local function addMath(char, fn)
	commands[char] = {desc = string.format("Calculate %s with input", char), args = {"numbers"}, exec = function(_, nums)
		nums = nums
		local o
		for _, n in ipairs(nums) do
			if not o then
				o = n
			else
				o = fn(o, n)
			end
		end
		return {o}
	end}
end

addMath("+", function(a, b) return a + b end)
addMath("*", function(a, b) return a * b end)
addMath("-", function(a, b) return a - b end)
addMath("/", function(a, b) return a / b end)
addMath("%", function(a, b) return a % b end)

return commands