-------------------------------
-- check Commands For Errors --
-------------------------------

local commands = require "commands"

return function(command)
  if not commands[command.source] then
		return
	end
  local needed = 0
	local possibleArgs
  local argList = commands[command.source].args
	local str
  if type(argList) == "string" then
		needed = 1
		possibleArgs = math.huge
		str = "One or more "..argList
  elseif type(argList) == "table" then
		local strList = {}
		for _, arg in ipairs(argList) do
			if type(arg) == "string" then
				needed = needed + 1
				table.insert(strList, arg)
			elseif type(arg) == "table" then
				possibleArgs = (possibleArgs or 0) + 1
				table.insert(strList, string.format("[%s]", arg[1]))
			end
		end
		str = table.concat(strList, ", ")
	end
	local args = #command.args
  if args < needed then
    return string.format("%s requires %s parameters (%s), got %s", command.source, needed, str, args)
	elseif args > (possibleArgs or needed) then
    return string.format("%s only takes %s parameters (%s), got %s\ntry passing multiple parameters as a [list]",
				command.source, possibleArgs or needed, str, args)
  end
end
