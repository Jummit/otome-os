--------------------
--    Commands    --
--------------------

local utils = require("utils")
local keys, escape, map, join = utils.keys, utils.escape, utils.map, utils.join

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
	args = "streams to combine", exec = function(_, sep, ...)
	  local r = {}
	  local streams = {...}
	  for i = 1, math.min(table.unpack(map(streams, function(e) return #e end))) do
	    table.insert(r, table.concat(map(streams, function(e) return e[i] end), sep[1]))
	  end
	  return r
	end
}
commands.splice = {desc = "Take one value from each input and splice them together",
	args = "streams to splice", exec = function(_, ...)
	  local r = {}
	  local streams = map({...}, function(a) return a end)
	  for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
	    for _, stream in ipairs(streams) do
	      table.insert(r, stream[i])
	    end
	  end
	  return r
	end
}
commands.read = {desc = "Show the content of the given files",
	args = "file names", exec = function(ctx, names)
	  local strs = {}
	  for _, file in ipairs(names) do
	    for _, k in ipairs(ctx:read(file) or {}) do
	      table.insert(strs, k)
	    end
	  end
	  return strs
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
commands.delete = {desc = "Delete the given files", args = "file names", exec = function(_, names)
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
commands.write = {desc = "Write something into a file", args = {"text to write", "The files"}, exec = function(_, text, file)
  return {"INS "..file[1].." "..table.concat(text, "\n")}
end}
commands.range = {desc = "Generate a sequence of numbers", args = {"from", "To"}, exec = function(_, from, to)
  local t = {}
  for i = tonumber(from[1]), tonumber(to[1]) do
    table.insert(t, i)
  end
  return t
end}
commands.history = {desc = "Show the history", exec = function(ctx)
  return map(join(ctx.history.history, ctx.history.reverts), function(h) return h.name end)
end}
commands.undo = {desc = "Undo an operation", args = {{"The amount of operations to undo"}}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local undoAction = ctx.history:undo()
    if not undoAction then break end
    table.insert(actions, undoAction.name)
  end
  return actions
end}
commands.redo = {desc = "Redo an operation", args = {{"The amount of operations to redo"}}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local toRedo = ctx.history:redo()
    if not toRedo then break end
    local name = toRedo.name:gsub("Undid ", "")
    table.insert(actions, name.." again")
  end
  return actions
end}
commands.describe = {desc = "Show help for the given commands", args = "the commands", exec = function(ctx, helpFor)
  return map(helpFor, function(c)
    if ctx.aliases[c] then
      return ctx.aliases[c]
    end
    return commands[c].desc
  end)
end}
commands.args = {desc = "Show args of a command", args = "the commands", exec = function(_, helpFor)
  return map(helpFor, function(c)
    local args = commands[c].args
    if type(args) == "table" then
      args = table.concat(args, ", ")
    end
    return args
  end)
end}
commands.alias = {desc = "Add a command alias", args = {"alias", "Command"}, exec = function(ctx, alias, cmd)
  ctx.aliases[alias[1]] = cmd[1]
  return {}
end}
commands.aliases = {desc = "Get a list of aliases", exec = function(ctx)
  return keys(ctx.aliases)
end}
commands.join = {desc = "Join a list of words", args = {"words", {"Separator"}}, exec = function(_, words, sep)
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