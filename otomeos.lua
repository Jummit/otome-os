#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
i = function(v) print(require ("inspect")(v)) end
local execute = require "execute"
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

  local function executeScript(file)
    lastResult = {}
    local script = lines(read(system.dir..file))
    if #script == 0 then return "File doesn't exist or is empty" end
    for lineNum, line in ipairs(script) do
      local res, err = execute(line, system)
      if not res then print(string.format("Error in script %s line %s: %s", file, lineNum, err)) break end
      for _, s in ipairs(res) do
        print(s:gsub("\n", "\\n"))
        system:execute(s)
        table.insert(lastResult, s)
      end
    end
  end

  executeScript("start")
  while true do
    io.write("> ")
    local line = io.read()
    local file = line:match("run (%w+)")
    if file then
      executeScript(file)
    else
      if line == "" or line == "x" then
        for _, v in ipairs(lastResult) do
          local err = system:execute(v)
          if err then
            print(err)
            break
          end
        end
        lastResult = {}
      else
        showResult(execute(line, system))
      end
    end
  end
end

main()
