-------------------------------
-- Check Commands For Errors --
-------------------------------

-- Checks for things like argument counts and type checking.

local describeArgs = require "describeArgs"
local parse = require "parser"

local cachedOk = {}

local function collectArguments(command, args)
  args = args or {}
  if command.arg then
    table.insert(args, command)
  end
  for _, arg in ipairs(command.args or {}) do
    collectArguments(arg, args)
  end
  return args
end

local function checkParameters(command, expected)
  for argNum, arg in ipairs(command.args) do
    if (arg.callable or false) ~= (expected[argNum].callable or false) then
      if arg.callable then
        return ("Didn't expect callable for parameter %s to %s"):format(
            argNum, command.command)
      else
        return ("Expected callable for parameter %s to %s"):format(
            argNum, command.command)
      end
    end
  end
end

local function checkCommand(command, about)
	local args = describeArgs(about.args)
	local argCount = #command.args
  if argCount < args.needed then
    return string.format("%s requires %s parameters (%s), got %s",
        command.command, args.needed, args.str, argCount)
	elseif args.limit and argCount > args.limit then
    return string.format(
        "%s only takes %s parameters (%s), got %s\ntry passing multiple parameters as a [list]",
				command.command, args.limit or args.needed, args.str, argCount)
  end
  local expected = {}
  for _, arg in ipairs(about.args) do
    table.insert(expected, {callable = arg:sub(1, 1) == "!"})
  end
  return checkParameters(command, expected)
end

local function checkFunction(func, content)
  local args = collectArguments(content)
  if #func.args ~= #args then
    return ("Expected %s parameters for function %s, got %s"):format(
        #args, func.command, #func.args)
  end
  return checkParameters(func.args, args)
end

local check
function check(command, system)
  for _, arg in ipairs(command.args or {}) do
    local err = check(arg, system)
    if err then
      return err
    end
  end
  if system.functions[command.command] then
    return checkFunction(command, system.functions[command.command])
  elseif system.commands[command.command] then
    return checkCommand(command, system.commands[command.command])
  end
end

return function(line, system)
  if cachedOk[line] then
    return
  end
  local command, err = parse(line)
  if err then return nil, err end
  err = check(command, system)
  cachedOk[command] = not err
  return err
end
