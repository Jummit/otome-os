#!/usr/bin/env lua5.3

--------------------
--   Main Loop    --
--------------------

local parse = require "parser"
local commands = require "commands"

local system = require "system"
system.files = {i = {"Ochar"}, onion = {
  "Onion was worshiped in the ancient Egypt. These plants were inevitable part",
  "of burial rituals and tombs of most rulers are covered with pictures of onion.",
  "Egyptians believed that onion possesses magic powers and that it can ensure",
  "success in the afterlife. Onion was even used as currency along with parsley",
  "and garlic.",
}}

local result
local function main()
  while true do
    io.write("> ")
    local i = io.read()
    if i == "" or i == "x" then
      for _, v in ipairs(result) do
        system:executeSystem(v)
      end
    else
      local command, err = parse(i, commands, {})
      if command then
        local args = commands[command.source].args
        if type(args) == "string" then args = 1
        elseif type(args) == "table" then args = #args
        else args = 0 end
        if #command.args < args then
          print(("Required %s parameters"):format(args))
        else
          result = command.cmd(system, table.unpack(command.args))
          for _, s in ipairs(result) do
            print(s)
          end
        end
      else
        print(err)
      end
    end
  end
end

main()
