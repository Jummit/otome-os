#!/usr/bin/env lua5.4

local tokenize = require "tokenizer"
local inspect = require "inspect"
local parse = require "parser"
local execute = require "interpreter"
local check = require "check"
local system = require "system"
i = function(v) print(require ("inspect")(v)) end

-- print(inspect(tokenize('command (sub{a = "b " b = c{a = 3}} "a b \\"c d") arg2')))
-- print(inspect(tokenize('a{r=b{i=c}}')))
-- print(inspect(parse('a{r=b{i=(c e \'b)}} e "A \\"" [1 2 !a]')))
-- print(inspect(parse('commands')))
-- print(inspect(execute('+ [1 2 3]', system)))
-- print(inspect(execute('join{with="\n"} [1 2 3]', system)))
-- print(inspect(parse('join{with="\n"} [!1 $2 $3]')))
-- system.functions.ma = parse('join [(!1 $2) 2]')
-- i(check("ma !join !files 5", system))
-- print(check("range !5 7", system))
-- print(check("give !5 7", system))
local res, err = execute("give !files ! { }7)", system)
print(err)
i(res)
-- i(check("ma !join files", system))
-- i(check("+ [1 2] 3", system))
-- print(inspect(parse('ma [(!1 $2) 2]')))
-- print(inspect(parse('a !join [1 2]')))
-- print(inspect(execute('ma !join [1 2]', system)))

-- cmd:A
-- cmd:A, configKey
-- cmd:A, configKey:r
-- cmd:A, configKey:r=
-- cmd:A, configKey:r=b
-- cmd:A:configKey:r=b
