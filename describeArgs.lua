return function(args)
  local needed = 0
	local limit = 0
	local str
  if type(args) == "string" then
		needed = 1
		limit = nil
		str = "one or more "..args
  elseif type(args) == "table" then
		local strList = {}
		for _, arg in ipairs(args) do
			if type(arg) == "string" then
				needed = needed + 1
				limit = limit + 1
				table.insert(strList, arg)
			elseif type(arg) == "table" then
				limit = limit + 1
				table.insert(strList, string.format("optionally %s", arg[1]))
			end
		end
		str = table.concat(strList, ", ")
	end
	return {
		str = str or "",
		needed = needed,
		limit = limit,
	}
end
