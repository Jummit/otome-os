--------------------
--     Parser     --
--------------------

local strip = require("utils").strip
local escape = require("utils").escape
local inspect = require "inspect"

local function cmdFromWord(word, commands, aliases)
  if word:sub(1, 1) == "'" or tonumber(word) then
    word = word:gsub("'", "", 1)
    return function() return {word} end
	elseif word:sub(1, 1) == '"' then
		word = word:sub(2, -2)
    return function() return {word} end
  elseif aliases[word] then
    return aliases[word]
  elseif commands[word] then
    return commands[word].exec
  else
    return nil, ("Command %s not found"):format(word)
  end
end

local function addWord(cur, word, commands, aliases)
  local cmd, err = cmdFromWord(word, commands, aliases)
  if not cmd then return nil, err end
  if not cur.cmd then
    cur.cmd = cmd
		cur.source = word
  else
    table.insert(cur.args, cmd)
  end
end

return function(str, commands, aliases)
  local stack = {{args = {}}}
  while #str > 0 do
		local next = str:sub(1,1)
    if next == "(" then
      table.insert(stack, {args = {}})
    elseif next == ")" then
      local sub = table.remove(stack)
			print("sarg", sub.source)
      table.insert(stack[#stack].args, function()
        return sub.cmd(table.unpack(sub.args))
      end)
		elseif next == '"' then
			next = str:match('"[^"]+"')
			addWord(stack[#stack], next, commands, aliases)
    else
      next = str:match('[^%s%()"]+')
      local cur = stack[#stack]
			addWord(cur, next, commands, aliases)
    end
		-- print(next, #stack)
    str = strip(str:gsub(escape(next), "", 1))
  end
	print(inspect(stack))
  return stack[1]
end

