return function(args)
  local needed = 0
	local limit = 0
	local str
	local strList = {}
	for _, arg in ipairs(args or {}) do
		local mod, name = arg:match("([%*%?]?)(.+)")
		if mod == "?" then
			limit = limit + 1
			table.insert(strList, string.format("optionally %s", name))
		elseif mod == "*" then
			needed = 1
			limit = nil
			table.insert(strList, "one or more "..name)
		else
			needed = needed + 1
			limit = limit + 1
			table.insert(strList, name)
		end
	end
	str = table.concat(strList, ", ")
	return {
		str = str,
		needed = needed,
		limit = limit,
	}
end
