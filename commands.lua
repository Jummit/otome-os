--------------------
--    Commands    --
--------------------

local utils = require("utils")
local keys, escape, map, join = utils.keys, utils.escape, utils.map, utils.join

local aliases = {}
local commands = {}
commands = {
  commands = {desc = "Show a list of available commands", exec = function(_)
    return keys(commands)
  end},
  replace = {desc = "", args = {"Original", "To replace", "With what to replace"}, exec = function(_, inp, from, to)
    return map(inp(), function(v)
      return v:gsub(escape(from()[1]), to()[1])
    end)
  end},
  combine = {desc = "Combine two streams", args = "Streams to combine", exec = function(_, ...)
    local r = {}
    local streams = map({...}, function(a) return a() end)
    for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
      table.insert(r, table.concat(map(streams, function(e) return e[i] end), "\t"))
    end
    return r
  end},
  splice = {desc = "Take one value from each input and splice them together", args = "Streams to splice", exec = function(_, ...)
    local r = {}
    local streams = map({...}, function(a) return a() end)
    for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
      for _, stream in ipairs(streams) do
        table.insert(r, stream[i])
      end
    end
    return r
  end},
  read = {desc = "Show the content of the given files", args = "File names", exec = function(ctx, names)
    local strs = {}
    for _, file in ipairs(names()) do
      for _, k in ipairs(ctx.files[file] or {}) do
        table.insert(strs, k)
      end
    end
    return strs
  end},
  files = {desc = "Show the available files", exec = function(ctx)
    return keys(ctx.files)
  end},
  new = {desc = "Create the given files", args = "File names", exec = function(_, names)
    return map(names(), function(n)
      return "NEW "..n
    end)
  end},
  delete = {desc = "Delete the given files", args = "File names", exec = function(_, names)
    return map(names(), function(n)
      return "DEL "..n
    end)
  end},
  resize = {desc = "Extend the stream", args = {"Amount", "Stream"}, exec = function(_, stream, count)
    local o = {}
    stream = stream()
    for i = 1, tonumber(count()[1]) do
      o[i] = stream[i] or stream[#stream]
    end
    return o
  end},
  time = {desc = "Show the time", exec = function(_)
    return { os.time() }
  end},
  list = {desc = "Create a list", args = "Elements of the list", exec = function(_, ...)
    local l = {}
    for _, arg in ipairs(table.pack(...)) do
      for _, val in ipairs(arg()) do
        table.insert(l, val)
      end
    end
    return l
  end},
  write = {desc = "Write something into a file", args = {"Text to write", "The files"}, exec = function(_, text, file)
    return {"INS "..file()[1].." "..table.concat(text(), "\n")}
  end},
  range = {desc = "Generate a sequence of numbers", args = {"From", "To"}, exec = function(_, from, to)
    local t = {}
    for i = tonumber(from()[1]), tonumber(to()[1]) do
      table.insert(t, i)
    end
    return t
  end},
  history = {desc = "Show the history", exec = function(ctx)
    return map(join(ctx.history, ctx.reverts), function(h) return h.name end)
  end},
  undo = {desc = "Undo an operation", args = {{"The amount of operations to undo"}}, exec = function(ctx, num)
    local actions = {}
    for _ = 1, num == nil and 1 or num()[1] do
      local toRevert = ctx.history[#ctx.history - #ctx.reverts]
      local revertAction = {name = "Undid "..toRevert.name, doFun = toRevert.undo, undo = toRevert.doFun}
      table.insert(ctx.reverts, revertAction)
      revertAction.doFun()
      table.insert(actions, revertAction.name)
    end
    return actions
  end},
  redo = {desc = "Redo an operation", args = {{"The amount of operations to redo"}}, exec = function(ctx, num)
    local actions = {}
    for _ = 1, num == nil and 1 or num()[1] do
      local toRedo = table.remove(ctx.reverts)
      toRedo.undo()
      local name = toRedo.name:gsub("Undid ", "")
      table.insert(actions, name.." again")
    end
    return actions
  end},
  help = {desc = "Show help for the given commands", args = "The commands", exec = function(_, helpFor)
    return map(helpFor(), function(c)
      if aliases[c] then
        return aliases[c].text
      end
      return commands[c].desc
    end)
  end},
  args = {desc = "Show args of a command", args = "The commands", exec = function(_, helpFor)
    return map(helpFor(), function(c)
      local args = commands[c].args
      if type(args) == "table" then
        args = table.concat(args, "")
      end
      return args
    end)
  end},
  alias = {desc = "Add a command alias", args = {"Alias", "Command"}, exec = function(_, alias, cmd)
    aliases[alias()[1]] = cmd
    return {alias()[1]}
  end},
  aliases = {desc = "Get a list of aliases", exec = function(_)
    return keys(aliases)
  end},
}

local function addMath(char, fn)
	commands[char] = {desc = string.format("Calculate %s with input", char), args = {"Numbers"}, exec = function(_, nums)
		nums = nums()
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

addMath("+", function(a,b) return a + b end)
addMath("*", function(a,b) return a * b end)
addMath("-", function(a,b) return a - b end)
addMath("/", function(a,b) return a / b end)
addMath("%", function(a,b) return a % b end)

return commands