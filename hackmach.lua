#!/usr/bin/env lua5.3

--------------------
--   Main Loop    --
--------------------

local system = require "system"
local execute = require "execute"

local function main()
  local lastResult
  while true do
    io.write("> ")
    local line = io.read()
    if line == "" or line == "x" then
      for _, v in ipairs(lastResult) do
        system:executeSystem(v)
      end
    else
      local result, err = execute(line, system)
      if result then
        lastResult = result
        for _, s in ipairs(result) do
          print(s)
        end
      else
        print(err)
      end
    end
  end
end

main()
