--------------------
--    Commands    --
--------------------

local utils = require("utils")
local describeArgs = require "describeArgs"
local keys, escape, map, join, shuffle, split = utils.keys, utils.escape, utils.map, utils.join, utils.shuffle, utils.split

local function intArg(command, param, val)
  if not val[1] then
    return nil, ('Got no value for parameter "%s" of command "%s"'):format(param, command)
  elseif not tonumber(val[1]) then
    return nil, ('Expected number for parameter "%s" of command "%s", got "%s"'):format(param, command, val[1])
  end
  return tonumber(val[1])
end

local commands = {}
commands.commands = {desc = "Show a list of available commands",
	exec = function(_)
	  return keys(commands)
	end
}
commands.functions = {desc = "Show a list of defined functions",
	exec = function(ctx)
	  return keys(ctx.functions)
	end
}
commands.when = {desc = "Return stream if stream isn't empty",
  args = {"test", "stream"},
	exec = function(_, test, stream)
    return #test > 0 and stream or {}
	end
}
commands.count = {desc = "Count the occurence of the values",
  args = {"count", "values"},
	exec = function(_, count, values)
    local o = {}
    for _, c in ipairs(count) do
      local n = 0
      for _, value in ipairs(values) do
        if value == c then
          n = n + 1
        end
      end
      table.insert(o, tostring(n))
    end
    return o
	end
}
commands.replace = {desc = "Find and replace inside the stream",
	args = {"text", "old", "new"},
	exec = function(_, inp, from, to)
	  return map(inp, function(v)
      for i, fr in ipairs(from) do
  	    v = v:gsub(escape(fr), to[i])
      end
      return v
	  end)
	end
}
commands.change = {desc = "Replace values", args = {"values", "old", "new"},
  exec = function(_, values, old, new)
    local o = {}
    for i, value in ipairs(values) do
      o[i] = value
      for j, oldval in ipairs(old) do
        if value == oldval then
          if not new[j] then
            return nil, ('No new value to replace index %s in command "change": expected %s new values, got %s'):format(i, #old, #new)
          end
          o[i] = new[j] or ""
        end
      end
    end
    return o
  end,
}
commands.every = {desc = "Get every nth value from a stream",
	args = {"nth", "stream"},
	exec = function(_, nth, inp)
    local o = {}
    local s = 1
    local by, err = intArg("every", "nth", nth)
    if err then return nil, err end
    local to = #inp
    if by < 0 then
      s = #inp
      to = 1
    elseif by == 0 then
      return nil, "Can't get every 0th element"
    end
    -- TODO: Allow variable distances.
    for i = s, to, by do
      table.insert(o, inp[i])
    end
    return o
	end
}
commands.combine = {desc = "Combine multiple streams",
	args = {"*streams to combine"}, exec = function(_, ...)
	  local r = {}
	  local streams = {...}
	  for i = 1, math.min(table.unpack(map(streams, function(e) return #e end))) do
      local vals = {}
      for _, stream in ipairs(streams) do
        table.insert(vals, stream[i])
      end
	    table.insert(r, table.concat(vals, " "))
	  end
	  return r
	end
}
commands.sort = {desc = "Sort the stream",
	args = {"words"}, exec = function(_, stream)
    local nums = {}
    for _, v in ipairs(stream) do
      local n = tonumber(v)
      if not n then break end
      table.insert(nums, n)
    end
    -- TODO: Add config option to enforce comparing numbers.
    -- stream = copy(stream)
    if #nums == #stream then
      stream = nums
    end
    table.sort(stream)
    for i, v in ipairs(stream) do
      stream[i] = tostring(v)
    end
    return stream
	end
}
commands.shuffle = {desc = "Randomize the stream",
	args = {"stream"}, exec = function(_, stream)
    -- stream = copy(stream)
    shuffle(stream)
    return stream
	end
}
commands.when = {desc = "Output if stream has values",
	args = {"bool", "stream"}, exec = function(_, bool, stream)
    if bool[1] and #bool[1] > 0 then
      return stream
    end
    return {}
	end
}
commands.reverse = {desc = "Invert the stream",
	args = {"stream"}, exec = function(_, stream)
    local n = {}
    for _ = 1, #stream do
      table.insert(n, table.remove(stream, #stream))
    end
    return n
	end
}
commands.indices = {desc = "Collect indices of occurences of values",
  args = {"stream", "tofind"}, exec = function(_, stream, tofind)
    local o = {}
    -- TODO: Use some different return value here. Pretty useless when given
    -- multiple values to find.
    for _, f in ipairs(tofind) do
      for i, v in ipairs(stream) do
        if v == f then
          table.insert(o, tostring(i))
        end
      end
    end
    return o
  end
}
commands.find = {desc = "Find text in a stream",
	args = {"query", "words"}, exec = function(_, query, stream)
    local n = {}
    for _, w in ipairs(stream) do
      for _, q in ipairs(query) do
        if w:find(q) then
          table.insert(n, w)
          break
        end
      end
    end
    return n
	end
}
commands.columns = {desc = "Combine multiple streams as columns",
	args = {"*streams"}, exec = function(_, ...)
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
	args = {"*streams"}, exec = function(_, ...)
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
	args = {"*files"}, exec = function(ctx, names)
	  return map(names, function(n) return ctx:read(n) end)
	end
}
commands.void = {desc = "Void the output",
	args = {"*files"}, exec = function()
    return {}
	end
}
commands.void = {desc = "Return nothing",
	exec = function() return {} end
}
commands.split = {desc = "Split the strings",
	args = {"*strings"}, exec = function(ctx, strings)
    local r = {}
    local sep = "\n"
    if ctx.cfg.at then
      sep = ctx.cfg.at[1]
    end
    for _, str in ipairs(strings) do
      for _, elem in ipairs(split(str, sep)) do
        table.insert(r, elem)
      end
    end
    return r
	end
}
commands.files = {desc = "Show the available files", exec = function(ctx)
  return ctx:getFiles()
end}
commands.new = {desc = "Create the given files", args = {"file names"}, exec = function(ctx, names)
  for _, name in ipairs(names) do
    ctx:new(name)
  end
  return {}
end}
commands.delete = {desc = "Delete the given files", args = {"*files"}, exec = function(ctx, names)
  for _, name in ipairs(names) do
    ctx:delete(name)
  end
  return {}
end}
commands.resize = {desc = "Extend the stream", args = {"stream", "length"},
  exec = function(ctx, stream, count)
    local o = {}
    local start = 1
    if ctx.cfg.start then
      start = tonumber(ctx.cfg.start[1])
    end
    -- TODO: Don't silently fail here.
    for i = start, tonumber(count[1]) or 0 do
      table.insert(o, stream[i] or stream[#stream])
    end
    return o
  end
}
commands.at = {desc = "Get value at indices", args = {"indices", "stream"},
  exec = function(_, indices, stream)
    local o = {}
    for _, i in ipairs(indices) do
      local num = tonumber(i)
      if not num then
        return nil, ('Can\'t use word "%s"as index for "at"'):format(i)
      end
      if num < 0 then
        num = #stream + num + 1
      end
      local val = stream[num]
      if val then
        table.insert(o, val)
      end
    end
    return o
  end
}
commands.removeat = {desc = "Remove values at indices",
  args = {"indices", "stream"}, exec = function(_, indices, stream)
    local o = {}
    for i, val in ipairs(stream) do
      local insert = true
      for _, r in ipairs(indices) do
        local num = tonumber(r)
        if not num then
          return nil, ('Expected number for index in command "removeat", got "%s"'):format(r)
        elseif num == 0 then
          return nil, 'Can\'t use zero as index in command "removeat"'
        end
        if num == i or #stream + num + 1 == i then
          insert = false
          break
        end
      end
      if insert then
        table.insert(o, val)
      end
    end
    return o
  end
}
commands.trim = {desc = "Remove values from the stream",
  args = {"stream", "amount"}, exec = function(_, stream, count)
    local o = {}
    local am, err = intArg("trim", "count", count)
    if err then return nil, err end
    local from, to = am + 1, #stream
    if am < 0 then
      from, to = 1, #stream + am
    end
    for i = from, to do
      table.insert(o, stream[i])
    end
    return o
  end
}
commands.time = {desc = "Show the time", exec = function(ctx)
  local part = (ctx.cfg.part or {})[1]
  if part then
    return {tostring(os.date("*t")[part])}
  end
  return { tostring(os.date()) }
end}
commands.give = {desc = "Execute a command for every set of values\nEach output is added to the output stream",
  args = {"!command", "*values"}, exec = function(ctx, command, ...)
    local streams = {...}
    local v = 0
    local o = {}
    local params = 1
    if ctx.cfg.args then
      -- TODO: Allow multiple arg counts.
      params = tonumber(ctx.cfg.args[1])
    end
    while true do
      local args = {}
      -- TODO: Improve variable naming.
      for _, stream in ipairs(streams) do
        local sa = {}
        for i = v * params, v * params + params - 1 do
          local val = stream[i + 1]
          if not val then return o end
          table.insert(sa, val)
        end
        table.insert(args, sa)
      end
      local res, err = command(table.unpack(args))
      if not res then return nil, err end
      for _, val in ipairs(res) do
        table.insert(o, val)
      end
      v = v + 1
    end
  end
}
commands["repeat"] = {
  desc = "Execute a command multiple times\nEach output is added to the output stream",
  args = {"!command", "values"}, exec = function(_, command, times)
    local o = {}
    -- TODO: Use all values from 'times'.
    if not times[1] then
      return nil, "Got no value for repeat times"
    end
    local num, err = intArg("repeat", "times", times)
    if err then return nil, err end
    if num < 1 then
      return nil, ('Can\'t repeat call %s times'):format(num)
    end
    for _ = 1, num do
      local res, err = command.call()
      if not res then return nil, err end
      for _, val in ipairs(res) do
        table.insert(o, val)
      end
    end
    return o
  end
}
commands.characters = {desc = "Return the characters in a stream",
  args = {"characters"}, exec = function(_, stream)
    local o = {}
    for _, i in ipairs(stream) do
      for a = 1, #i do
        table.insert(o, i:sub(a, a))
      end
    end
    return o
  end
}
commands.size = {desc = "Count elements of the stream", args = {"values"}, exec = function(_, values)
  return { tostring(#values) }
end}
commands.length = {desc = "Count length of elements of the stream", args = {"values"}, exec = function(_, values)
  local o = {}
  for _, v in ipairs(values) do
    table.insert(o, tostring(#v))
  end
  return o
end}
commands.list = {desc = "Create a list", args = {"*elements"}, exec = function(_, ...)
  local l = {}
  -- for _, arg in ipairs(table.pack(...)) do
  for _, arg in ipairs({...}) do
    for _, val in ipairs(arg) do
      table.insert(l, val)
    end
  end
  return l
end}
commands.write = {desc = "Write something into a file", args = {"text", "files"}, exec = function(ctx, text, file)
  ctx:write(file[1], table.concat(text, "\n"))
  return text
end}
commands.unique = {desc = "Return stream with unique values",
  args = {"values"}, exec = function(ctx, values)
    local count = {}
    local o = {}
    local max = 1
    if ctx.cfg.max then
      max = tonumber(ctx.cfg.max[1])
    end
    for _, v in ipairs(values) do
      if not count[v] or count[v] < max then
        count[v] = (count[v] or 0) + 1
        table.insert(o, v)
      end
    end
    return o
  end
}
commands.range = {desc = "Generate a sequence of numbers", args = {"from", "to"}, exec = function(_, from, to)
  local t = {}
  local from, fromErr = intArg("range", "from", from)
  local to, toErr = intArg("range", "to", to)
  if fromErr or toErr then return nil, fromErr or toErr end
  -- TODO: Use all numbers from from and to.
  -- TODO: Add step parameter
  for i = from, to, to > from and 1 or -1 do
    table.insert(t, tostring(i))
  end
  return t
end}
commands.history = {desc = "Show the history", exec = function(ctx)
  return map(join(ctx.history.history, ctx.history.reverts), function(h) return h.name end)
end}
commands.undo = {desc = "Undo an operation", args = {"?number of operations"}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local undoAction = ctx.history:undo()
    if not undoAction then break end
    table.insert(actions, undoAction.name)
  end
  return actions
end}
commands.redo = {desc = "Redo an operation", args = {"?number of operations"}, exec = function(ctx, num)
  local actions = {}
  for _ = 1, num == nil and 1 or num[1] do
    local toRedo = ctx.history:redo()
    if not toRedo then break end
    local name = toRedo.name:gsub("Undid ", "")
    table.insert(actions, name.." again")
  end
  return actions
end}
commands.describe = {desc = "Show help for the given commands", args = {"!command"}, exec = function(ctx, helpFor)
  -- TODO: Allow adding function descriptions here.
  if ctx.functions[helpFor.command.command] then
    return {ctx.functions[helpFor.command.command].definition}
  end
  if commands[helpFor.command.command] then
    return {commands[helpFor.command.command].desc}
  end
  -- TODO: Maybe just show the source code of the closure here.
  return nil, "Can't get description of closure."
end}
commands.arguments = {desc = "Show args of a command", args = {"!command"}, exec = function(_, callable)
  if commands[callable.command.command] then
    return commands[callable.command.command].args or {}
  end
  -- TODO: Collect function parameters.
  return nil, "Can't get parameters of closure"
end}
commands.join = {desc = "Join a list of words", args = {"words"}, exec = function(ctx, words)
  local every = 1000
  local with = " "
  if ctx.cfg.pack then
    every = tonumber(ctx.cfg.pack[1])
  end
  if ctx.cfg.with then
    with = ctx.cfg.with[1]
  end
  local o = {}
  for i = 1, #words, every do
    local con = table.concat(words, with, i, math.min(i + every - 1, #words))
    table.insert(o, con)
  end
	return o
end}
commands["or"] = {desc = "Return the first stream with values", args = {"*streams"},
  exec = function(_, ...)
    for _, stream in ipairs({...}) do
      if #stream > 0 then return stream end
    end
    return {}
end}
commands.remove = {desc = "Remove values from a stream", args = {"remove", "stream"},
  exec = function(_, remove, stream)
    local l = #stream
    local ri = {}
    for _, toRemove in ipairs(remove) do
      for i in ipairs(stream) do
        if stream[i] == toRemove then
          ri[i] = true
        end
      end
    end
    local n = {}
    for i = 1, l do
      if not ri[i] then
        table.insert(n, stream[i])
      end
    end
    return n
end}

local function addMath(char, fn)
	commands[char] = {desc = string.format("Calculate %s with input", char),
    args = {"numbers"}, exec = function(_, nums)
		local o
		for _, n in ipairs(nums) do
			if not o then
				o = tonumber(n)
        if not o then return {} end
			else
        local num = tonumber(n)
        if not num then
          return nil, ('Can\'t do math operation %s with word "%s"'):format(char, n)
        end
        if num then
  				o = fn(o, num)
        end
			end
		end
    if not o then
      return {}
    end
		return {tostring(o)}
	end}
end

local function addCmp(char, fn)
	commands[char] = {desc = string.format("Compare input with %s", char), args = {"numbers"}, exec = function(_, nums)
		local o
		for _, n in ipairs(nums) do
			if not o then
				o = tonumber(n)
        if not o then return {} end
			else
        local num = tonumber(n)
        if not num then
          return nil, ("Can't compare %s with numbers. Use 'sort' if you want to sort words instead."):format(n)
        end
        if not fn(o, num) then
          return {}
        end
			end
		end
		return nums
	end}
end

addMath("+", function(a, b) return a + b end)
addMath("*", function(a, b) return a * b end)
addMath("-", function(a, b) return a - b end)
addMath("/", function(a, b) return a / b end)
addMath("%", function(a, b) return a % b end)
addCmp(">", function(a, b) return a > b end)
addCmp("<", function(a, b) return a < b end)
addCmp("equal", function(a, b) return a == b end)

return commands