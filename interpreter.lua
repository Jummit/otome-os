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

local execute
function execute(command, system, functionArgs, directArgs)
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
  if not directArgs then
    for _, arg in ipairs(command.args or {}) do
      local evaluated, err = execute(arg, system, functionArgs)
      if err then return nil, err end
      table.insert(evaluatedArgs, evaluated)
    end
  else
    evaluatedArgs = directArgs
  end

  local evaluatedConfig = {}
  for k, v in pairs(command.config or {}) do
    evaluatedConfig[k] = execute(v, system, functionArgs)
  end

  if command.callable and command.arg and functionArgs then
    return execute({command = functionArgs[command.callableArg],
        args = command.args}, system, functionArgs)
  elseif command.arg then
    if not functionArgs then
      return nil, ("Tried to use parameter %s outside of function"):format(command.arg)
    end
    return functionArgs[command.arg]
  elseif command.callable then
    return {
      call = function(...)
        local cmd = setmetatable({callable = false, args = {...}}, {__index = command})
        local err = check(cmd, system)
        if err then return nil, "Error in callable execution: "..err end
        return execute(cmd, system, functionArgs, {...})
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
    assert(type(res) == "table", ('Command "%s" didn\'t return a list'):format(command.command))
    return res
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
  res, err = execute(res, system)
  if err then
    return nil, err
  elseif type(res) == "function" then
    return nil, "Unexpected callable"
  end
  return res
end
