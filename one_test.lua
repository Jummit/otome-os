#!/usr/bin/env lua5.4
local test = require "test"
local assertExec = test.assertExec
-- test.all()
-- assertExec('function about (combine $1 (resize ": " 100) (!2 $1))')
-- test.system:execute('FUN about combine $1 (resize ": " 100) (!2 $1)')
-- assertExec("about functions !describe", {""})

test.system:execute('FUN call !1')
assertExec("call !commands")
