#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
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

  local pendingScript

  local function startScript(file)
    pendingScript = {
      lines = lines(read(system.dir..file)),
      line = 1,
      name = file,
    }
  end

  local function executeScript()
    lastResult = {}
    for lineNum = pendingScript.line, #pendingScript.lines do
      local line = pendingScript.lines[lineNum]
      if line == "confirm" then
        print("Script requested execution of the output. Continue with [Return]")
        pendingScript.line = lineNum + 1
        return
      end
      local res, err = execute(line, system)
      if not res then print(string.format("Error in script %s line %s: %s", pendingScript.name, lineNum, err)) break end
      for _, s in ipairs(res) do
        s = s:gsub("\n", "\\n")
        print(s)
      end
      for _, v in ipairs(res) do
        table.insert(lastResult, v)
      end
    end
    pendingScript = nil
  end

  startScript("start")
  executeScript()
  while true do
    io.write("> ")
    local line = io.read()
    local file = line:match("run (%w+)")
    if file then
      startScript(file)
    end
    if line == "" or line == "x" then
      for _, v in ipairs(lastResult) do
        local err = system:execute(v)
        if err then
          print(err)
          break
        end
      end
      lastResult = {}
      if pendingScript then
        executeScript()
      end
    else
      showResult(execute(line, system))
    end
  end
end

main()
