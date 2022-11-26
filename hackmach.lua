#!/usr/bin/env lua5.3

--------------------
--   Main Loop    --
--------------------

local system = require "system"
local execute = require "execute"
-- system.files = {i = {"Ochar"}, onion = {
--   "Onion was worshiped in the ancient Egypt. These plants were inevitable part",
--   "of burial rituals and tombs of most rulers are covered with pictures of onion.",
--   "Egyptians believed that onion possesses magic powers and that it can ensure",
--   "success in the afterlife. Onion was even used as currency along with parsley",
--   "and garlic.",
-- }}

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
