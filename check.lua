local commands = require "commands"

return function(command)
  local args = 0
  if commands[command.source] then
    args = commands[command.source].args
    if type(args) == "string" then
			args = 1
    elseif type(args) == "table" then
			args = #args
    else
			args = 0
		end
  end
  if #command.args < args then
    return string.format("%s requires %s parameters, got %s", command.source, args, #command.args)
  end
end
