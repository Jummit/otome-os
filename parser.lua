--------------------
--     Parser     --
--------------------

-- Parses a string into a syntax tree.

local tokenize = require "tokenizer"

local function parse(line)
  local tokens = tokenize(line)
  local cursor = 1
  for _, v in ipairs(tokens) do
    -- print(v.type, v.value or "")
  end

  local function read()
    cursor = cursor + 1
    local token = tokens[cursor - 1]
    if token then
      -- print(token.type, token.value or "")
    end
    return tokens[cursor - 1]
  end

  local function peek()
    return tokens[cursor]
  end

  local readCommand, readCommandWithArgs

  local function readConfig()
    assert(read().type == "{")
    local vals = {}
    while true do
      local key = read()
      if key.type == "}" then
        break
      end
      assert(read().type == "=")
      local val = readCommand()
      vals[key.value] = val
    end
    return vals
  end

  local function readList()
    local list = {values = {}}
    while true do
      local element = peek()
      if element.type == "]" then
        read()
        break
      end
      table.insert(list.values, readCommand())
    end
    return list
  end

  function readCommand()
    local start = read()
    if start.type == "number" then
      return { number = start.value }
    elseif start.type == "string" then
      return { string = start.value }
    end
    if start.type == "(" then
      return readCommandWithArgs()
    elseif start.type == "!" then
      local command = readCommand()
      command.callable = true
      return command
    end
    if start.type == "[" then
      return readList()
    end
    local command = {}
    command.command = start.value
    local after = peek()
    if after and after.type == "{" then
      command.config = readConfig()
    end
    after = peek()
    return command
  end

  local function readParameters()
    local args = {}
    local arg = peek()
    while arg and arg.type ~= "}" and arg.type ~= ")" do
      table.insert(args, readCommand())
      arg = peek()
    end
    if arg and arg.type == ")" then
      read()
    end
    return args
  end

  function readCommandWithArgs()
    local command = readCommand()
    local after = peek()
    if after then
      command.args = readParameters()
    end
    return command
  end

  return readCommandWithArgs()
end

return parse
