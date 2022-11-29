--------------------
--     Parser     --
--------------------

local strip = require("utils").strip
local escape = require("utils").escape
local check = require "check"

local function cmdFromWord(word, commands)
  if word:sub(1, 1) == "'" or tonumber(word) then
    local inner = word:gsub("'", "", 1)
    return function() return {inner} end
	elseif word:sub(1, 1) == '"' then
		local inner = word:sub(2, -2)
    return function() return {inner} end
  elseif commands[word] then
    return commands[word].exec
  else
    return nil, ("Command %s not found"):format(word)
  end
end

local function addWord(stack, word, commands, functions)
  local cmd = {source = word, args = {}}
  if not functions[word] then
    local wordCmd, err = cmdFromWord(word, commands)
    if not wordCmd then return err end
    cmd.cmd = wordCmd
  end
	local cur = stack[#stack]
	if not next(cur) then
		stack[#stack] = cmd
	else
    table.insert(cur.args, cmd)
  end
end

local parse

local function parseFunction(str, commands, aliases, functions)
  local name, body = str:match("function (%w+)%s?%((.+)%)$")
  local cmd, err = parse(body, commands, aliases, functions)
  if not cmd then return nil, err end
  err = check(cmd, commands)
	if err then return nil, err end
  return {
    cmd = function(ctx)
      ctx.functions[name] = cmd
      return {string.format("Function %s declared", name)}
    end,
    args = {},
  }
end

function parse(str, commands, aliases, functions)
  if str:find("function") == 1 then
    return parseFunction(str, commands, aliases, functions)
  end
  local stack = {{}}
  while #str > 0 do
		local next = str:sub(1,1)
    if next == "(" then
      table.insert(stack, {})
    elseif next == ")" then
      if #stack == 1 then
        return nil, "Excess closing parenthesis"
      end
      table.insert(stack[#stack - 1].args, table.remove(stack))
    elseif next == "[" then
      table.insert(stack, {args = {}, cmd = commands.list.exec, source = "Square brackets"})
    elseif next == "]" then
      table.insert(stack[#stack - 1].args, table.remove(stack))
		elseif next == '"' then
			next = str:match('"[^"]+"')
			local err = addWord(stack, next, commands, functions)
			if err then return nil, err end
    elseif next == "{" then
      local last = stack[#stack]
      local lastArgs = last.args
      last = lastArgs[#lastArgs] or last
      local args = str:match("[^}]+"):sub(2)
      last.config = last.config or {}
      for k, v in args:gmatch("(%w+)%s?=%s?(%S+)") do
        local cmd, err = parse(v, commands, aliases, functions)
        if not cmd then return nil, err end
        last.config[k] = cmd
      end
      next = str:match("[^}]+}")
    else
      next = str:match('[^%s%()%[%]{"]+')
      if aliases[next] then
        str = aliases[next]..str
      else
  			local err = addWord(stack, next, commands, functions)
  			if err then return nil, err end
      end
    end
    str = strip(str:gsub(escape(next), "", 1))
  end
  if #stack > 1 then
    return nil, "Mismatched parenthesis"
  end
  return stack[1]
end

return parse
