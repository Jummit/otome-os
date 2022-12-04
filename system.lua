------------------------
--  Operating System  --
------------------------

-- The system object stores the state of the computer.
-- It can execute system commands.

local parse = require "parser"
local check = require "check"
local execute = require "interpreter"
local filesystem = require "filesystem"
local getFiles = filesystem.getFiles
local read = filesystem.read
local write = filesystem.write
local lines = require("utils").lines

local system = {
	dir = "/home/jummit/.local/share/otomeos/",
	old = "/home/jummit/.local/share/otomeos/old/",
	history = require("history")(),
  commands = require "commands",
  functions = {},
  files = {},
  disableUndo = false,
}

function system:getFiles()
	return getFiles(self.dir)
end

function system:read(file)
  if self.files[file] then
    return self.files[file]
  end
	return read(self.dir..file) or ""
end

function system:write(file, content)
  local path = self.dir..file
  if self:read(file) == content then
    return
  end
  local tmpName = self.old..tostring(math.random())
  if self.disableUndo then
    self.files[file] = content
    return
  end
  return self.history:addAction(
    ("Inserted %s into %s"):format(content, content),
    function()
      os.rename(path, tmpName)
      write(path, content)
    end,
    function()
      os.remove(path)
      os.rename(tmpName, path)
    end
  )
end

function system:new(file)
  local path = self.dir..file
  local tmpName = self.old..tostring(math.random())
  return self.history:addAction("Created "..file,
    function()
      os.rename(path, tmpName)
      write(path, "")
    end,
    function()
      os.remove(path)
      os.rename(tmpName, path)
    end
  )
end

function system:delete(file)
  local path = self.dir..file
  local tmpName = self.old..tostring(math.random())
  return self.history:addAction("Deleted "..file,
    function()
      os.rename(path, tmpName)
    end,
    function()
      os.rename(tmpName, path)
    end
  )
end

function system:registerFunction(name, body)
  local parsedCmd, parseErr = parse(body)
  if not parsedCmd then return nil, parseErr end
  local err = check(parsedCmd, self)
	if err then return nil, err end
  parsedCmd.definition = body
  local before = self.functions[name]
  self.history:addAction("Registered function "..name,
    function()
      self.functions[name] = parsedCmd
    end,
    function()
      self.functions[name] = before
    end)
end

function system:executeScript(file)
  local allRes = {}
  local script = lines(read(system.dir..file))
  if #script == 0 then return "File doesn't exist or is empty" end
  for lineNum, line in ipairs(script) do
    local res, err = self:executeLine(line)
    if err then
      return nil, string.format("Error in script %s line %s: %s", file,
          lineNum, err)
    end
    for _, v in ipairs(res or {}) do
      table.insert(allRes, v)
    end
  end
  return allRes
end

function system:executeLine(line)
  local file = line:match("run (%w+)")
  local funName, funBody = line:match("^function (%S+)%s?(.*)")
  if file then
    return self:executeScript(file)
  elseif funName then
    local err = system:registerFunction(funName, funBody)
    if err then return nil, err end
  else
    return execute(line, system)
  end
end

return system
