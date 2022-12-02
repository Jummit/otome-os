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
  local lastResult = {}
  local function showResult(result, err)
    if result then
      lastResult = result
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
      if #line > 0 and line:sub(1, 1) ~= "#" then
        local res, err = executeLine(line)
        if err then
          return nil, string.format("Error in script %s line %s: %s", file,
              lineNum, err)
        end
        if type(res) == "string" then res = {res} end
        for _, s in ipairs(res or {}) do
          local action, exerr = system:execute(s)
          if exerr then
            return nil, exerr
          end
          table.insert(allRes, s)
        end
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
      return system:execute(("FUN %s %s"):format(funName, funBody))
    else
      return execute(line, system)
    end
  end

  showResult(executeScript("start"))
  if arg[1] == "--script" then
    showResult(executeScript(arg[2]))
    do return end
  end
  while true do
    io.write("> ")
    showResult(executeLine(io.read()))
  end
end

main()
