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
			return nil, ("Tried to use parameter %s outside"):format(command.arg)
		end
		return functionArgs[command.arg]
	elseif command.callable then
		return function(...)
			return execute(setmetatable({callable = false}, {__index = command}),
					system, functionArgs, {...})
		end
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
		return nil, ("Command %s not found"):format(command.command)
	end
end

return function(line, system)
	assert(type(line) == "string")
	local err = check(line, system)
	if err then return nil, err end
	local res, parseErr = parse(line)
	if parseErr then
		return nil, parseErr
	elseif not res then
		return {}
	end
	return execute(res, system)
end
