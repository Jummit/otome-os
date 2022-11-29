local parse = require "parser"
local check = require "check"

local resolveCommand
-- Recursively resolve commands to a value.
function resolveCommand(command, system, functionParameters)
	local args = {}
	if command.arg then
		if functionParameters then
			if command.arg > #functionParameters then
				return nil, string.format("Insufficient parameters, only got %s", #functionParameters)
			end
			return functionParameters[command.arg]
		else
			return nil, string.format("Can't use parameter %s outside function", command.arg)
		end
	end
	for _, arg in ipairs(command.args) do
		local argCommand, err = resolveCommand(arg, system, functionParameters)
		if err then return nil, err end
		table.insert(args, argCommand)
	end
	command.args = args
	local fun = system.functions[command.source]
	if fun then
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
