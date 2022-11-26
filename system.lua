------------------------
--  System Execution  --
------------------------

local strip = require("utils").strip
local join = require("utils").join
local filesystem = require "filesystem"
local getFiles = filesystem.getFiles
local read = filesystem.read

local system = {
	aliases = {},
	dir = "/home/jummit/.local/share/otomeos/",
	history = require("history")(),
}

function system:getFiles()
	return getFiles(self.dir)
end

function system:read(file)
	local content = read(self.dir..file) or ""
	local lines = {}
	for line in content:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	return lines
end

function system:execute(line)
  local s = line:find(" ")
  local cmd, param = line:sub(1, s - 1), line:sub(s + 1)
  if cmd == "NEW" then
    local old = self.files[param]
    self.history:addAction("Created "..param,
      function() self.files[param] = {} end,
      function() self.files[param] = old end
    )
  elseif cmd == "DEL" then
    local old = self.files[param]
		local trashName = tostring(math.random())
    self.history:addAction("Deleted "..param,
      function() self.files[param] = nil end,
      function() self.files[param] = old end
    )
  elseif cmd == "INS" then
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
