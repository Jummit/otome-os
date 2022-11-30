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

local function getCmd(word, commands, functions)
  if functions[word] then
    return {fun = word, source = word, args = {}}
  else
    local wordCmd, err = cmdFromWord(word, commands)
    if not wordCmd then return nil, err end
    return {cmd = wordCmd, source = word, args = {}}
  end
end

local function addWord(stack, word, commands, functions)
  local cmd, err = getCmd(word, commands, functions)
  if not cmd then return err end
	local cur = stack[#stack]
	if not next(cur) then
		stack[#stack] = cmd
	else
    table.insert(cur.args, cmd)
  end
end

local parse

local function parseFunction(str, commands, functions)
  local name, body = str:match("function (%w+)%s?%((.+)%)$")
  local cmd, err = parse(body, commands, functions)
  if not cmd then return nil, err end
  err = check(cmd, commands)
	if err then return nil, err end
  return {
    cmd = function(_)
      return {string.format("FUN %s %s", name, body)}
    end,
    args = {},
    source = "function",
  }
end

-- Parse the str into a nested structure of commands with parameters.
-- Example:
-- {
--   args = {<command>},
--   cmd = function,
--   source = "name",
-- }
-- 
-- Function parameters look like this:
-- {
--   arg = 1,
--   source = "$1",
-- }
-- They get looked up during the execution step.
--
-- Callable function parameters look like this:
-- {
--   arg = 1,
--   source = "!1",
-- }
--
-- Callable function parameter:
-- {
--   source = "!1",
--   call = true,
--   arg = 1,
-- }
--
-- Callable command passed to a function:
-- {
--   source = "!word",
--   call = function,
-- }
function parse(str, commands, functions)
  if str:find("function ") == 1 then
    return parseFunction(str, commands, functions)
  end
  -- An empty table on the stack means that a command is expected.
  local stack = {{}}
  while #str > 0 do
		local part = str:sub(1,1)
    if part == "(" then
      table.insert(stack, {})
    elseif part == ")" or part == "]" then
      if #stack == 1 then
        return nil, "Excess closing brackets"
      end
      table.insert(stack[#stack - 1].args, table.remove(stack))
    elseif part == "[" then
      table.insert(stack, {args = {}, cmd = commands.list.exec, source = "Square brackets"})
		elseif part == '"' then
			part = str:match('"[^"]+"')
			local err = addWord(stack, part, commands, functions)
			if err then return nil, err end
    elseif part == "{" then
      local last = stack[#stack]
      local lastArgs = last.args
      last = lastArgs[#lastArgs] or last
      local args = str:match("[^}]+"):sub(2)
      last.config = last.config or {}
      for k, v in args:gmatch("(%w+)%s?=%s?(%S+)") do
        local cmd, err = parse(v, commands, functions)
        if not cmd then return nil, err end
        last.config[k] = cmd
      end
      part = str:match("[^}]+}")
    elseif part == "$" then
      part = str:match("%$%d+")
    	local cur = stack[#stack]
      local num = tonumber(part:match("%d+"))
      if not cur.args then
        return nil, string.format(
          "Can't use function parameter as a command. Use !%s instead", num)
      end
      table.insert(cur.args, {source = part, arg = num})
    elseif part == "!" then
      part = str:match("!%w+")
      if not part then return nil, "Expected command name after !" end
    	local cur = stack[#stack]
      local num = tonumber(part:match("%d+"))
      if num then
        local cmd = {source = part, arg = num, call = true, args = {}}
      	if not next(cur) then
      		stack[#stack] = cmd
      	else
          table.insert(cur.args, cmd)
        end
      else
        local cmd, err = getCmd(part:sub(2), commands, functions)
        if not cmd then return nil, err end
        cmd.call = true
        cmd.source = part
        table.insert(cur.args, cmd)
      end
    else
      part = str:match('[^%s%()%[%]{"]+')
			local err = addWord(stack, part, commands, functions)
			if err then return nil, err end
    end
    str = strip(str:gsub(escape(part), "", 1))
  end
  if #stack > 1 then
    return nil, "Mismatched parenthesis"
  end
  return stack[1]
end

return parse
