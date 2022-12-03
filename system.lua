------------------------
--  Operating System  --
------------------------

-- The system object stores the state of the computer.
-- It can execute system commands.

local strip = require("utils").strip
local join = require("utils").join
local parse = require "parser"
local check = require "check"
local filesystem = require "filesystem"
local getFiles = filesystem.getFiles
local read = filesystem.read
local copy = filesystem.copy
local write = filesystem.write

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
  return self.history:addAction("Registered function "..name,
    function()
      self.functions[name] = parsedCmd
    end,
    function()
      self.functions[name] = before
    end)
end

return system
