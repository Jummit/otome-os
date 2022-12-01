#!/usr/bin/env lua5.4
local test = require "test"
local utils = require "utils"
i = function(v) print(require ("inspect")(v)) end
local assertExec = test.assertExec
test.all()
-- local a, b = i(utils.split("ab largerb str", "b%s")), i{"a", "larger", "str"}
-- assert(a == b, ("%s is not %s"):format(a, b))
