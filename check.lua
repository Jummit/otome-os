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
    -- TODO: Confirm that commands are uniform, starting from one.
    -- TODO: Check type compatibility. Can't use same command for
    -- different types.
    args[command.arg] = command
  end
  for _, arg in ipairs(command.args or {}) do
    collectArguments(arg, args)
  end
  return args
end

local function checkParameters(command, expected)
  if not command.args then
    return
  end
  for argNum, arg in ipairs(command.args) do
    local expectedArg = expected[math.min(argNum, #expected)]
    if (arg.callable or false) ~= (expectedArg.callable or false) then
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
	local argCount = #(command.args or {})
  if argCount < args.needed then
    return string.format("%s requires %s parameters (%s), got %s",
        command.command, args.needed, args.str, argCount)
	elseif args.limit and argCount > args.limit then
    if args.limit == 0 then
      return ("%s doesn't take any parameters, but got %s"):format(
          command.command, #command.args)
    else
      return string.format(
          "%s only takes %s parameters (%s), got %s\ntry passing multiple parameters as a [list]",
  				command.command, args.limit or args.needed, args.str, argCount)
    end
  end
  local expected = {}
  for _, arg in ipairs(about.args or {}) do
    table.insert(expected, {callable = arg:sub(1, 1) == "!"})
  end
  return checkParameters(command, expected)
end

local function checkFunction(func, content)
  local args = collectArguments(content)
  if not func.callable and #(func.args or {}) ~= #args then
    return ("Expected %s parameters for function %s, got %s"):format(
        #(args or {}), func.command, #(func.args or {}))
  end
  return checkParameters(func, args)
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
  assert(type(line) == "string")
  if cachedOk[line] then
    return
  end
  local command, err = parse(line)
  if err then return nil, err end
  err = check(command, system)
  cachedOk[command] = not err
  return err
end
