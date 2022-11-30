local parse = require "parser"
local check = require "check"
local copy = require ("utils").copy
local inspect = require "inspect"


-- function about (combine $1 (resize ": " 100) (!2 $1))
-- about functions !describe
-- about {"about"} {1: !describe}
-- about 

local resolveCommand
-- Recursively resolve commands to a value.
-- Parameters are resolved first.
-- Function parameters are collected and passed to the sub-resolveCommand
-- call when a function is reached. How long that will hold up is unclear.
-- The command is something returned from the parser.
function resolveCommand(command, system, functionParameters)
	local args = {}
	if type(command.call) == "function" then
		return command
	end
	if command.arg then
		if functionParameters then
			if command.arg > #functionParameters then
				return nil, string.format("Insufficient parameters for function %s, only got %s",
					functionParameters.name, #functionParameters)
			end
			if command.call then
				local arg = copy(functionParameters[command.arg])
				if not arg.call then
					-- TODO: Move this to check. Probably all of this.
					return nil, string.format("Expected callable for parameter %s to function %s", command.arg, functionParameters.name)
				end
				arg.args = command.args
				arg.cmd = arg.call
				arg.call = nil
				return resolveCommand(arg, system, functionParameters)
			else
				return functionParameters[command.arg]
			end
		else
			return nil, string.format("Can't use parameter %s outside function",
				command.arg)
		end
	end
	for _, arg in ipairs(command.args or {}) do
		local argCommand, err = resolveCommand(arg, system, functionParameters)
		if err then return nil, err end
		table.insert(args, argCommand)
	end
	local fun = system.functions[command.source]
	if fun then
		args.name = command.source
		return resolveCommand(fun, system, args)
	end
  local err = check(command, system.commands)
	if err then return nil, err end
	local cfg = {}
	for k, v in pairs(command.config or {}) do
		cfg[k] = resolveCommand(v, system, functionParameters)
	end
  return command.cmd(setmetatable({cfg=cfg}, {__index=system}), table.unpack(args))
end

local function execute(line, system)
  local command, err = parse(line, system.commands, system.functions)
  if not command then
    return nil, err
  end
	return resolveCommand(command, system)
end

return execute
