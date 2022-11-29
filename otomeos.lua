#!/usr/bin/env lua5.4

--------------------
--   Main Loop    --
--------------------

local system = require "system"
local execute = require "execute"

local function main()
  local lastResult
  local function showResult(result, err)
    if result then
      lastResult = result
      for _, s in ipairs(result) do
        print(s)
      end
    else
      print(err)
    end
  end

  showResult(execute("run (split (read 'start))", system))
  while true do
    io.write("> ")
    local line = io.read()
    if line == "" or line == "x" then
      for _, v in ipairs(lastResult) do
        local err = system:execute(v)
        if err then
          print(err)
          break
        end
      end
    else
      showResult(execute(line, system))
    end
  end
end

main()
