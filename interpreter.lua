-----------------
-- Interpreter --
-----------------

-- Executes a line of code.

local parse = require "parser"

local execute
function execute(command, system)
	local evaluatedArgs = {}
	for _, arg in ipairs(command.args or {}) do
		local evaluated = execute(arg, system)
		table.insert(evaluatedArgs, evaluated)
	end
	local evaluatedConfig = {}
	for k, v in pairs(command.config or {}) do
		evaluatedConfig[k] = execute(v, system)
	end
	if system.commands[command.command] then
		local cmd = system.commands[command.command]
		local context = setmetatable({cfg = evaluatedConfig}, {__index = system})
		return cmd.exec(context, table.unpack(evaluatedArgs))
	elseif command.values then
		return execute({command = "list", args = command.values}, system)
	elseif command.number then
		return {command.number}
	elseif command.string then
		return {command.string}
	else
		i(command)
		error(command)
	end
end

return function(line, system)
	return execute(parse(line), system)
end
