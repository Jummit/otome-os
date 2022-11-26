-------------------------------
-- check Commands For Errors --
-------------------------------

local commands = require "commands"

return function(command)
  local needed
	local possibleArgs
  if commands[command.source] then
    local args = commands[command.source].args
    if type(args) == "string" then
			needed = 1
			possibleArgs = math.huge
    elseif type(args) == "table" then
---@diagnostic disable-next-line: param-type-mismatch
			for _, arg in ipairs(args) do
				if type(arg) == "string" then
					needed = (needed or 0) + 1
				elseif type(arg) == "table" then
					possibleArgs = possibleArgs + 1
				end
			end
		end
  end
	if needed or possibleArgs then
		local args = #command.args
	  if args < needed then
	    return string.format("%s requires %s parameters, got %s", command.source, needed, args)
		elseif args > (possibleArgs or needed) then
	    return string.format("%s only takes %s parameters, got %s\ntry passing multiple parameters as a [list]",
					command.source, possibleArgs or needed, args)
	  end
	end
end
