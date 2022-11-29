------------------------
--  System Execution  --
------------------------

local strip = require("utils").strip
local join = require("utils").join
local filesystem = require "filesystem"
local getFiles = filesystem.getFiles
local read = filesystem.read
local copy = filesystem.copy
local write = filesystem.write

local system = {
	aliases = {},
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
  local s = line:find(" ")
  local cmd, param = line:sub(1, s - 1), line:sub(s + 1)
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
  end
end

return system
