#!/usr/bin/env lua5.4
local test = require "test"
i = function(v) print(require ("inspect")(v)) end
local assertExec = test.assertExec
test.all()
