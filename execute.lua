local parse = require "parser"
local check = require "check"

local resolveCommand
function resolveCommand(command, system)
	local args = {}
	for _, arg in ipairs(command.args) do
		local argCommand, err = resolveCommand(arg, system)
		if err then return nil, err end
		table.insert(args, argCommand)
	end
	command.args = args
  local err = check(command, system.commands)
	if err then return nil, err end
	local cfg = {}
	for k, v in pairs(command.config or {}) do
		cfg[k] = resolveCommand(v, system)
	end
  return command.cmd(setmetatable({cfg=cfg}, {__index=system}), table.unpack(args))
end

local function execute(line, system)
  local command, err = parse(line, system.commands, system.aliases)
  if not command then
    return nil, err
  end
	return resolveCommand(command, system)
end

return execute
