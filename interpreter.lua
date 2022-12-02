-----------------
-- Interpreter --
-----------------

-- Executes a line of code.

local parse = require "parser"

local execute
function execute(command, system, functionArgs, directArgs)
	local evaluatedArgs = {}
	if not directArgs then
		for _, arg in ipairs(command.args or {}) do
			-- i(arg)
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

	if command.callable and command.arg then
		return execute({command = functionArgs[command.callableArg],
				args = command.args}, system, functionArgs)
	elseif command.arg then
		if not functionArgs then
			return nil, "Not in function"
		end
		if not functionArgs[command.arg] then
			return nil, "Function got not enough params"
		end
		return functionArgs[command.arg]
	elseif command.callable then
		return function(...)
			return execute(setmetatable({callable = false}, {__index = command}), system, functionArgs, {...})
		end
	elseif command.values then
		return execute({command = "list", args = command.values}, system, functionArgs)
	elseif command.number then
		return {command.number}
	elseif command.string then
		return {command.string}
	elseif system.functions[command.command] then
		return execute(system.functions[command.command], system, evaluatedArgs)
	elseif system.commands[command.command] then
		local cmd = system.commands[command.command]
		local context = setmetatable({cfg = evaluatedConfig}, {__index = system})
		return cmd.exec(context, table.unpack(evaluatedArgs))
	else
		i(command)
		return nil, ("Command %s not found"):format(command.command)
	end
end

return function(line, system)
	return execute(parse(line), system)
end
