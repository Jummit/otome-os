-----------------
-- Interpreter --
-----------------

-- Executes a line of code.
-- Parameters are evaluated first.
-- There are four layers, each can result in an error:
--
-- 1. Lexer: Read tokens from string
-- 2. Parser: Parse into abstract syntax tree
-- 3. Interpreter: Execute the syntax tree
-- 4. Commands: Process data

local check = require "check"
local parse = require "parser"

local visualize
function visualize(command)
  if command.string then
    return command.string
  elseif command.number then
    return command.number
  elseif command.command then
    local args = {}
    for _, arg in ipairs(command.args or {}) do
      table.insert(args, visualize(arg))
    end
    if #args == 0 then
      if command.callable then
        return "!"..command.command
      else
        return command.command
      end
    else
      local s = ("%s (%s)"):format(command.command, table.concat(args, " "))
      if command.callable then
        s = "!("..s..")"
      end
      return s
    end
  elseif command.arg then
    return "$"..command.arg
  else
    i(command)
    error()
  end
end

-- This function evaluates an syntax tree parsed by the parser.
-- The end product is either a list of strings, a callable object or an error.
--
-- That's not all: It can also return a "parameter" object used inside a
-- function or callable definition ($1). These are looked up in "functionArgs"
-- when they are evaluated as parameters to a command.
-- 
-- functionArgs is passed when executing a function or closure.

local depth = 0
local root_execute
local function execute(command, system, functionArgs)
  print(string.rep("  ", depth)..visualize(command))
  depth = depth + 1
  local res, err = root_execute(command, system, functionArgs)
  depth = depth - 1
  return res, err
end

function root_execute(command, system, functionArgs)
  if command.args and #command.args > 0 and command.callable then
    return {
      call = function(...)
        local cmd = setmetatable({callable = false}, {__index = command})
        local err = check(cmd, system)
        if err then return nil, "Error in callable execution: "..err end
        return execute(cmd, system, {...})
      end,
      command = command,
    }
  end
  local evaluatedArgs = {}
  for _, arg in ipairs(command.args or {}) do
    local evaluated, err = execute(arg, system, functionArgs)
    if err then return nil, err end
    table.insert(evaluatedArgs, evaluated)
  end

  local evaluatedConfig = {}
  for k, v in pairs(command.config or {}) do
    evaluatedConfig[k] = execute(v, system, functionArgs)
  end

  if command.callable and command.arg and functionArgs then
    -- A closure.
    return execute({command = functionArgs[command.callableArg],
        args = command.args}, system, functionArgs)
  elseif command.arg then
    if not functionArgs then
      return nil, ("Tried to use parameter %s outside of function"):format(
          command.arg)
    end
    -- The returned parameter is stored inside the evaluatedArgs of
    -- another command.
    return functionArgs[command.arg]
  elseif command.callable then
    return {
      call = function(...)
        -- Set callable to false to force actual evaluation of the command.
        local cmd = setmetatable({callable = false, args = {...}},
            {__index = command})
        local err = check(cmd, system)
        if err then return nil, "Error in callable execution: "..err end
        return execute(cmd, system, functionArgs)
      end,
      command = command,
    }
  elseif command.number then
    return {command.number}
  elseif command.string then
    return {command.string}
  elseif system.functions[command.command] then
    return execute(system.functions[command.command], system, evaluatedArgs)
  elseif system.commands[command.command] then
    local cmd = system.commands[command.command]
    local context = setmetatable({cfg = evaluatedConfig}, {__index = system})
    local res, err = cmd.exec(context, table.unpack(evaluatedArgs))
    if err then return nil, err end
    assert(type(res) == "table",
        ('Command "%s" didn\'t return a list, but "%s"'):format(
        command.command, res))
    return res
  elseif command[1] then
    -- Tried to evaluate an already evaluated list.
    return command
  else
    return nil, ("Command %s not found"):format(command.command)
  end
end

return function(line, system)
  assert(type(line) == "string")
  local res, parseErr = parse(line)
  if parseErr then
    return nil, parseErr
  elseif not res then
    return {}
  end
  local err = check(res, system)
  if err then return nil, err end
  res, err = execute(res, system, {{}})
  if not res then
    return nil, err
  elseif res.call then
    return nil, "Unexpected callable"
  end
  return res
end
