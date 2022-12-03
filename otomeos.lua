#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
i = function(v) print(require ("inspect")(v)) end
local execute = require "interpreter"
local read = require("filesystem").read
local lines = require("utils").lines

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

  local executeLine
  local function executeScript(file)
    local allRes = {}
    local script = lines(read(system.dir..file))
    if #script == 0 then return "File doesn't exist or is empty" end
    for lineNum, line in ipairs(script) do
      local res, err = executeLine(line)
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

  function executeLine(line)
    local file = line:match("run (%w+)")
    local funName, funBody = line:match("^function (%S+)%s?(.*)")
    if file then
      return executeScript(file)
    elseif funName then
      local res, err = system:registerFunction(funName, funBody)
      if err then return nil, err end
      return {res}
    else
      return execute(line, system)
    end
  end

  showResult(executeScript("start"))
  if arg[1] == "--script" then
    showResult(executeScript(arg[2]))
    do return end
  end
  system.disableUndo = true
  while true do
    io.write("> ")
    showResult(executeLine(io.read()))
  end
end

main()
