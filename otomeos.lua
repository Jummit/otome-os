#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
i = function(v) print(require ("inspect")(v)) end

local function main()
  local function showResult(result, err)
    if result then
      for _, s in ipairs(result) do
        s = s:gsub("\n", "\\n")
        print(s)
      end
    else
      print(err)
    end
  end


  showResult(system:executeScript("start"))
  if arg[1] == "--script" then
    showResult(system:executeScript(arg[2]))
    do return end
  end
  system.disableUndo = true
  while true do
    io.write("> ")
    showResult(system:executeLine(io.read()))
  end
end

main()
