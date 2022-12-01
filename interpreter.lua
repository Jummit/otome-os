-----------------
-- Interpreter --
-----------------

-- Executes a line of code.

local parse = require "parser"

local execute
function execute(command, system, functionArgs)
	local evaluatedArgs = {}
	for _, arg in ipairs(command.args or {}) do
		i(arg)
		local evaluated = execute(arg, system, functionArgs)
		table.insert(evaluatedArgs, evaluated)
	end
	local evaluatedConfig = {}
	for k, v in pairs(command.config or {}) do
		evaluatedConfig[k] = execute(v, system, functionArgs)
	end
	if system.functions[command.command] then
		return execute(system.functions[command.command], system, evaluatedArgs)
	elseif system.commands[command.command] then
		local cmd = system.commands[command.command]
		local context = setmetatable({cfg = evaluatedConfig}, {__index = system})
		return cmd.exec(context, table.unpack(evaluatedArgs))
	elseif command.values then
		return execute({command = "list", args = command.values}, system, functionArgs)
	elseif command.number then
		return {command.number}
	elseif command.string then
		return {command.string}
	elseif command.arg then
		if not functionArgs then
			return nil, "Not in function"
		end
		return functionArgs[command.arg]
	elseif command.callable then
		return command.callable
	elseif command.callableArg then
		return execute({command = functionArgs[command.callableArg],
				args = command.args}, system, functionArgs)
	else
		return nil, ("Command %s not found"):format(command.command)
	end
end

return function(line, system)
	return execute(parse(line), system)
end
