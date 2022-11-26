local parse = require "parser"
local check = require "check"
local commands = require "commands"

local resolveCommand
function resolveCommand(command, system)
	local args = {}
	for _, arg in ipairs(command.args) do
		table.insert(args, resolveCommand(arg, system))
	end
  local err = check(command)
	if err then return nil, err end
  return command.cmd(system, table.unpack(args))
end

local function execute(line, system)
  local command, err = parse(line, commands, system.aliases)
  if not command then
    return nil, err
  end
	return resolveCommand(command, system)
end

return execute
