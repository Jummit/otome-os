------------------------
--  System Execution  --
------------------------

local strip = require("utils").strip
local join = require("utils").join

local system = {
	files = {},
	history = require("history")(),
}

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
