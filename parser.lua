--------------------
--     Parser     --
--------------------

local strip = require("utils").strip
local escape = require("utils").escape

local function cmdFromWord(word, commands)
  if word:sub(1, 1) == "'" or tonumber(word) then
    local inner = word:gsub("'", "", 1)
    return {cmd = function() return {inner} end, source = word}
	elseif word:sub(1, 1) == '"' then
		local inner = word:sub(2, -2)
    return {cmd = function() return {inner} end, source = word}
  elseif commands[word] then
    return {cmd = commands[word].exec, source = word}
  else
    return nil, ("Command %s not found"):format(word)
  end
end

local function addWord(stack, word, commands)
  local cmd, err = cmdFromWord(word, commands)
  if not cmd then return err end
	local cur = stack[#stack]
	cmd.args = {}
	if not next(cur) then
		stack[#stack] = cmd
	else
    table.insert(cur.args, cmd)
  end
end

return function(str, commands, aliases)
	str = str:gsub("%a+", function(s)
		return aliases[s] or s
	end)
  local stack = {{}}
  while #str > 0 do
		local next = str:sub(1,1)
    if next == "(" then
      table.insert(stack, {})
    elseif next == ")" then
      table.insert(stack[#stack - 1].args, table.remove(stack))
    elseif next == "[" then
      table.insert(stack, {args = {}, cmd = commands.list.exec, source = "Square brackets"})
    elseif next == "]" then
      table.insert(stack[#stack - 1].args, table.remove(stack))
		elseif next == '"' then
			next = str:match('"[^"]+"')
			local err = addWord(stack, next, commands)
			if err then return nil, err end
    else
      next = str:match('[^%s%()%[%]"]+')
			local err = addWord(stack, next, commands)
			if err then return nil, err end
    end
    str = strip(str:gsub(escape(next), "", 1))
  end
  return stack[1]
end

