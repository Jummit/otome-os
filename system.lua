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
	trash = "/home/jummit/.local/share/otomeos/trash/",
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
  local tmpName = tostring(math.random())
  local file = self.dir..param
  if cmd == "NEW" then
    self.history:addAction("Created "..param,
      function()
        os.rename(file, self.trash..tmpName)
        write(file, "")
      end,
      function()
        os.remove(file)
        os.rename(self.trash..tmpName, file)
      end
    )
  elseif cmd == "DEL" then
    self.history:addAction("Deleted "..param,
      function() os.rename(file, tmpName) end,
      function() os.rename(tmpName, file) end
    )
  elseif cmd == "MOV" then
    -- TODO: Implement move
  elseif cmd == "INS" then
    -- TODO: Implement inserting actual text
    local file
    param = strip(param:gsub("^%S+", function(e) file = e return "" end, 1))
    local old = self.files[param]
    self.history:addAction("Inserted into "..file,
      function() self.files[file] = join(old or {}, {param}) end,
      function() self.files[file] = old end
    )
  elseif cmd == "FUN" then
    local parsedCmd, err = parse(data, self.commands, self.functions)
    if not parsedCmd then return err end
    err = check(parsedCmd, self.commands)
  	if err then return err end
    parsedCmd.definition = data
    local before = self.functions[param]
    self.history:addAction("Registered function "..param,
      function()
        self.functions[param] = parsedCmd
      end,
      function()
        self.functions[param] = before
      end)
  end
end

return system
