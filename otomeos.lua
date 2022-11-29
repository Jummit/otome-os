#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
local execute = require "execute"

local function showResult(result, err)
  if result then
    for _, s in ipairs(result) do
      print(s)
    end
  else
    print(err)
  end
end

local function main()
  showResult(execute("run (split (read 'start))", system))
  local lastResult
  while true do
    io.write("> ")
    local line = io.read()
    if line == "" or line == "x" then
      for _, v in ipairs(lastResult) do
        system:execute(v)
      end
    else
      local result, err = execute(line, system)
      showResult(result, err)
      lastResult = result or lastResult
    end
  end
end

main()
