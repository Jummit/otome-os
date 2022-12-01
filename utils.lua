--------------------
-- Some Utilities --
--------------------

local utils = {}

function utils.strip(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function utils.join(...)
  local sum = {}
  for _, t in ipairs(table.pack(...)) do
    for _, v in ipairs(t) do table.insert(sum, v) end
  end
  return sum
end

function utils.escape(text)
    return text:gsub("([^%w])", "%%%1")
end

function utils.keys(t)
  local list = {}
  for k in pairs(t) do
    table.insert(list, k)
  end
  return list
end

-- function utils.map(t, fun)
--   local len = #t
--   return setmetatable({}, {__index = function(_, k)
--     if t[k] == nil then return nil end
--     return fun(t[k])
--   end,
--   __len = function() return len end
--   })
-- end

function utils.map(t, fun)
  local r = {}
  for k, v in pairs(t) do
    r[k] = fun(v)
  end
  return r
end

function utils.copy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

function utils.lines(text)
  local lines = {}
	for line in text:gmatch("[^\n]+") do
		table.insert(lines, line)
	end
  return lines
end

function utils.shuffle(t)
  for i = #t, 2, -1 do
    local e = math.random(i)
    t[i], t[e] = t[e], t[i]
  end
  return t
end

function utils.split(str, at)
  local parts = {}
  while true do
    local start, to = str:find(at)
    if not start then
      table.insert(parts, str)
      break
    end
    table.insert(parts, str:sub(1, start - 1))
    str = str:sub(to + 1)
  end
  return parts
end

return utils
