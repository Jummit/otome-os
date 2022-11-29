#!/usr/bin/env lua5.4
local test = require "test"
local assertExec = test.assertExec
-- test.all()
assertExec("function two (list $1 $2)")
assertExec("two 1 2", {"1", "2"})
