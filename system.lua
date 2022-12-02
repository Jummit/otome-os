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
}

function system:getFiles()
	return getFiles(self.dir)
end

function system:read(file)
	return read(self.dir..file) or ""
end

function system:execute(line)
  local cmd, param, data = line:match("(%S+) (.-) (.+)")
  if not param then return end
  local tmpName = self.old..tostring(math.random())
  local file = self.dir..param
  if cmd == "NEW" then
    return self.history:addAction("Created "..param,
      function()
        os.rename(file, tmpName)
        write(file, "")
      end,
      function()
        os.remove(file)
        os.rename(tmpName, file)
      end
    )
  elseif cmd == "DEL" then
    return self.history:addAction("Deleted "..param,
      function() os.rename(file, tmpName) end,
      function() os.rename(tmpName, file) end
    )
  elseif cmd == "MOV" then
    -- TODO: Implement move
  elseif cmd == "INS" then
    return self.history:addAction("Inserted into "..file,
      function()
        os.rename(file, tmpName)
        write(file, data)
      end,
      function()
        os.remove(file)
        os.rename(tmpName, file)
      end
    )
  elseif cmd == "FUN" then
    local err = check(data, self)
  	if err then return nil, err end
    local parsedCmd, parseErr = parse(data)
    if not parsedCmd then return nil, parseErr end
    parsedCmd.definition = data
    local before = self.functions[param]
    return self.history:addAction("Registered function "..param,
      function()
        self.functions[param] = parsedCmd
      end,
      function()
        self.functions[param] = before
      end)
  end
end

return system
