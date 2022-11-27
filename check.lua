-------------------------------
-- check Commands For Errors --
-------------------------------

local describeArgs = require "describeArgs"

return function(command, commands)
  if not commands[command.source] then
		return
	end
	local args = describeArgs(commands[command.source].args)
	local argCount = #command.args
  if argCount < args.needed then
    return string.format("%s requires %s parameters (%s), got %s", command.source, args.needed, args.str, argCount)
	elseif args.limit and argCount > args.limit then
    return string.format("%s only takes %s parameters (%s), got %s\ntry passing multiple parameters as a [list]",
				command.source, args.limit or args.needed, args.str, argCount)
  end
end
