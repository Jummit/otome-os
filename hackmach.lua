local files = {i = {"Ochar"}, onion = {
  "Onion was worshiped in the ancient Egypt. These plants were inevitable part",
  "of burial rituals and tombs of most rulers are covered with pictures of onion.",
  "Egyptians believed that onion possesses magic powers and that it can ensure",
  "success in the afterlife. Onion was even used as currency along with parsley",
  "and garlic.",
}}

-- Other possibility:
-- replace-text (show-file get-files) apple banana

-- Command Arg1 Arg2 (SubCommand Arg1 Arg2)
-- Commands can be called to return a stream of any length
-- Args can be commands that return streams
-- The result of the root is printed
-- Commands are basically maps of on stream to another
-- square brackets [] can be used to convert a list of arguments into a stream:
-- "new [a b c d]" will create files a b c and d
-- for now, use list

-- OS
-- has repl
-- has separate command instruction format to perform tasks:
-- DEL file
-- INS smth
-- MOV file
-- Only read operations can be executed by commands
-- Output of Commands can be executed using X
-- X without commands executes the last output
-- X with command executes that command as system
-- All operations can be undone. This adds the REV instruction to the history
--
-- Edit/Debug/Fix cycle:
-- !write (edit (read 'somefile)) 'somefile
-- (Editor is now open, when quit a system command is printed to stdout)
-- x

-- TODO: Tests, Strings, List sugar, Flow control: loops, conditions, aliases,
-- immediate execution, error handling, folders

-- Project inspired by: Bash, ZSH, Exapunks, Blender Geometry Nodes, Lisp/Functional Programming

--------------------
-- Some Utilities --
--------------------

local function strip(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function join(...)
  local sum = {}
  for _, t in ipairs(table.pack(...)) do
    for _, v in ipairs(t) do table.insert(sum, v) end
  end
  return sum
end

local function escape(text)
    return text:gsub("([^%w])", "%%%1")
end

local function keys(t)
  local list = {}
  for k in pairs(t) do
    table.insert(list, k)
  end
  return list
end

local function map(t, fun)
  local len = #t
  return setmetatable({}, {__index = function(_, k)
    if t[k] == nil then return nil end
    return fun(t[k])
  end,
  __len = function() return len end
  })
end

--------------------
--    History     --
--------------------

local history = {}
local reverts = {}

local function undoable(name, doFun, undo)
  history = join(history, reverts)
  table.insert(history, {name = name, doFun = doFun, undo = undo})
  doFun()
  print(name)
  reverts = {}
end

--------------------
--System Execution--
--------------------

local function executeSystem(line)
  local s = line:find(" ")
  local cmd, param = line:sub(1, s - 1), line:sub(s + 1)
  if cmd == "NEW" then
    local old = files[param]
    undoable("Created "..param,
      function() files[param] = {} end,
      function() files[param] = old end
    )
  elseif cmd == "DEL" then
    local old = files[param]
    undoable("Deleted "..param,
      function() files[param] = nil end,
      function() files[param] = old end
    )
  elseif cmd == "INS" then
    local file
    param = strip(param:gsub("^%S+", function(e) file = e return "" end, 1))
    local old = files[param]
    undoable("Inserted into "..file,
      function() files[file] = join(old or {}, {param}) end,
      function() files[file] = old end
    )
  end
end

--------------------
--    Commands    --
--------------------

local aliases = {}
local commands = {}
commands = {
  commands = {desc = "Show a list of available commands", function()
    return keys(commands)
  end},
  replace = {desc = "", args = {"Original", "To replace", "With what to replace"}, function(inp, from, to)
    return map(inp(), function(v)
      return v:gsub(escape(from()[1]), to()[1])
    end)
  end},
  combine = {desc = "Combine two streams", args = "Streams to combine", function(...)
    local r = {}
    local streams = map({...}, function(a) return a() end)
    for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
      table.insert(r, table.concat(map(streams, function(e) return e[i] end), "\t"))
    end
    return r
  end},
  splice = {desc = "Take one value from each input and splice them together", args = "Streams to splice", function(...)
    local r = {}
    local streams = map({...}, function(a) return a() end)
    for i = 1, math.max(table.unpack(map(streams, function(e) return #e end))) do
      for _, stream in ipairs(streams) do
        table.insert(r, stream[i])
      end
    end
    return r
  end},
  read = {desc = "Show the content of the given files", args = "File names", function(names)
    local strs = {}
    for _, file in ipairs(names()) do
      for _, k in ipairs(files[file] or {}) do
        table.insert(strs, k)
      end
    end
    return strs
  end},
  files = {desc = "Show the available files", function()
    return keys(files)
  end},
  new = {desc = "Create the given files", args = "File names", function(names)
    return map(names(), function(n)
      return "NEW "..n
    end)
  end},
  delete = {desc = "Delete the given files", args = "File names", function(names)
    return map(names(), function(n)
      return "DEL "..n
    end)
  end},
  resize = {desc = "Extend the stream", args = {"Amount", "Stream"}, function(stream, count)
    local o = {}
    stream = stream()
    for i = 1, tonumber(count()[1]) do
      o[i] = stream[i] or stream[#stream]
    end
    return o
  end},
  time = {desc = "Show the time", function()
    return { os.time() }
  end},
  calc = {desc = "Calculate a result using the given numbers", args = {"Operation", "Numbers"}, function(m, v)
    return {load("return "..table.concat(v(), m()[1]))()}
  end},
  list = {desc = "Create a list", args = "Elements of the list", function(...)
    local l = {}
    for _, arg in ipairs(table.pack(...)) do
      for _, val in ipairs(arg()) do
        table.insert(l, val)
      end
    end
    return l
  end},
  write = {desc = "Write something into a file", args = {"Text to write", "The files"}, function(text, file)
    return {"INS "..file()[1].." "..table.concat(text(), "\n")}
  end},
  range = {desc = "Generate a sequence of numbers", args = {"From", "To"}, function(from, to)
    local t = {}
    for i = tonumber(from()[1]), tonumber(to()[1]) do
      table.insert(t, i)
    end
    return t
  end},
  history = {desc = "Show the history", function()
    return map(join(history, reverts), function(h) return h.name end)
  end},
  undo = {desc = "Undo an operation", args = {{"The amount of operations to undo"}}, function(num)
    local actions = {}
    for _ = 1, num == nil and 1 or num()[1] do
      local toRevert = history[#history - #reverts]
      local revertAction = {name = "Undid "..toRevert.name, doFun = toRevert.undo, undo = toRevert.doFun}
      table.insert(reverts, revertAction)
      revertAction.doFun()
      table.insert(actions, revertAction.name)
    end
    return actions
  end},
  redo = {desc = "Redo an operation", args = {{"The amount of operations to redo"}}, function(num)
    local actions = {}
    for _ = 1, num == nil and 1 or num()[1] do
      local toRedo = table.remove(reverts)
      toRedo.undo()
      local name = toRedo.name:gsub("Undid ", "")
      table.insert(actions, name.." again")
    end
    return actions
  end},
  help = {desc = "Show help for the given commands", args = "The commands", function(helpFor)
    return map(helpFor(), function(c)
      if aliases[c] then
        return aliases[c].text
      end
      return commands[c].desc
    end)
  end},
  args = {desc = "Show args of a command", args = "The commands", function(helpFor)
    return map(helpFor(), function(c)
      local args = commands[c].args
      if type(args) == "table" then
        args = table.concat(args, "")
      end
      return args
    end)
  end},
  alias = {desc = "Add a command alias", args = {"Alias", "Command"}, function(alias, cmd)
    aliases[alias()[1]] = cmd
    return {alias()[1]}
  end},
  aliases = {desc = "Get a list of aliases", function()
    return keys(aliases)
  end},
}

--------------------
--     Parser     --
--------------------

local function cmdFromWord(word)
  if word:sub(1, 1) == "'" or tonumber(word) then
    word = word:gsub("'", "", 1)
    return function() return {word} end
  elseif aliases[word] then
    return aliases[word]
  elseif commands[word] then
    return commands[word][1]
  else
    return nil, ("Command %s not found"):format(word)
  end
end

local function parse(str)
  local stack = {{args = {}}}
  while #str > 0 do
    if str:sub(1,1) == "(" then
      table.insert(stack, {args = {}})
      str = str:sub(2)
    elseif str:sub(1,1) == ")" then
      local sub = table.remove(stack)
      table.insert(stack[#stack].args, function()
        return sub.cmd(table.unpack(sub.args))
      end
      )
      str = str:sub(2)
    else
      local next = str:match("[^%()]+")
      local cur = stack[#stack]
      if next then
        for word in strip(next):gmatch("%S+") do
          local cmd, err = cmdFromWord(word)
          if not cmd then return nil, err end
          if not cur.cmd then
            cur.cmd = cmd
            cur.command = commands[word]
          else
            table.insert(cur.args, cmd)
          end
        end
      end
      str = strip(str:gsub(escape(next), "", 1))
      end
  end
  return stack[1]
end

--------------------
--   Main Loop    --
--------------------

local result
local function main()
  while true do
    io.write("> ")
    local i = io.read()
    if i == "" or i == "x" then
      for _, v in ipairs(result) do
        executeSystem(v)
      end
    else
      local command, err = parse(i)
      if command then
        local args = command.command.args
        if type(args) == "string" then args = 1
        elseif type(args) == "table" then args = #args
        else args = 0 end
        if #command.args < args then
          print("Required parameters")
        else
          result = command.cmd(table.unpack(command.args))
          for _, s in ipairs(result) do
            print(s)
          end
        end
      else
        print(err)
      end
    end
  end
end

main()
