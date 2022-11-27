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

function utils.map(t, fun)
  local len = #t
  return setmetatable({}, {__index = function(_, k)
    if t[k] == nil then return nil end
    return fun(t[k])
  end,
  __len = function() return len end
  })
end

function utils.copy(t)
  local copy = {}
  for k, v in ipairs(t) do
    copy[k] = v
  end
  return copy
end

return utils
