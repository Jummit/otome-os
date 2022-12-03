--------------------
--     Parser     --
--------------------

-- Parses a string into a syntax tree.

local tokenize = require "tokenizer"

local function parse(line)
  assert(type(line) == "string")

  local tokens = tokenize(line)
  local cursor = 1

  local function read()
    cursor = cursor + 1
    return tokens[cursor - 1]
  end

  local function peek()
    return tokens[cursor]
  end

  local readCommand, readCommandWithArgs

  local function readConfig()
    assert(read().type == "{")
    local vals = {}
    local key = read()
    if not key then
      return nil, "Expected key value pairs inside config"
    end
    while key.type ~= "}" do
      if read().type ~= "=" then
        return nil, "Expected equal sign-value pairs inside config"
      end
      local val, err = readCommand()
      if err then return nil, err end
      vals[key.value] = val
      key = read()
    end
    return vals
  end

  local function readList()
    local list = {command = "list", args = {}}
    while true do
      local element = peek()
      if not element then
        return nil, "Expected list elements"
      end
      if element.type == "]" then
        read()
        break
      end
      local arg, err = readCommand()
      if err then return nil, err end
      table.insert(list.args, arg)
    end
    return list
  end

  function readClosure()
  end

  function readCommand()
    local start = read()
    if not start then
      return nil, "Unclosed opening paranthesis"
    elseif start.type == "number" then
      return { number = tostring(start.value) }
    elseif start.type == "string" then
      return { string = start.value }
    elseif start.type == "$" then
      -- TODO: Parse named config parameters here.
      local val = read()
      if not val.value then
        return nil, "Expected number after function parameter start"
      end
      local arg = tonumber(val.value)
      if not arg then
        return nil, ("Malformed function parameter: %s"):format(val.value)
      end
      return { arg = arg }
    elseif start.type == ")" then
      return nil, "Empty block"
    elseif start.type == "{" then
      return nil, "Unexpected config start"
    elseif start.type == "}" then
      return nil, "Unexpected closing config bracket"
    elseif start.type == "=" then
      return nil, "Unexpected equal sign"
    elseif start.type == "#" then
      while read() do end
      return nil
    elseif start.type == "(" then
      local cmd, err = readCommandWithArgs()
      if err then return nil, err end
      local last = read()
      if not last or last.type ~= ")" then
        return nil, "Expected closing parenthesis"
      end
      return cmd
    elseif start.type == "!" then
      if not peek() then
        return nil, "Expected command or number after callable start"
      end
      if peek().type == "number" then
        return { callable = true, arg = read().value }
      end
      local command, err = readCommand()
      if err then return nil, err end
      command.callable = true
      return command
    elseif start.type == "[" then
      return readList()
    end
    local command = {}
    command.command = start.value
    local after = peek()
    if after and after.type == "{" then
      local conf, err = readConfig()
      if err then return nil, err end
      command.config = conf
    end
    return command
  end

  local function readParameters()
    local args = {}
    local arg = peek()
    while arg and arg.type ~= "}" and arg.type ~= ")" do
      local res, err = readCommand()
      if err then return nil, err end
      table.insert(args, res)
      arg = peek()
    end
    return args
  end

  function readCommandWithArgs()
    local command, err = readCommand()
    if not command then return nil, err end
    command.hasArgs = true
    local after = peek()
    if after then
      local arg, argErr = readParameters()
      if argErr then return nil, argErr end
      command.args = arg
    end
    return command
  end

  if not peek() then return nil end
  local cmd, err = readCommandWithArgs()
  if err then return nil, err end
  if cursor < #tokens then
    return nil, "Unexpected closing parenthesis"
  end
  return cmd
end

return parse
