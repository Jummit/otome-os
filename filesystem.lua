local filesystem = {}

function filesystem.getFiles(dir)
  local files = {}
  local out = io.popen("ls -1 "..dir):read("a")
  for file in out:gmatch("[^\n]+") do
    table.insert(files, file)
  end
  return files
end

function filesystem.read(file)
  -- local f <close> = io.open(file)
  local f = io.open(file)
  if not f then return end
  return f:read("a")
end

function filesystem.copy(file, to)
  os.execute(string.format("cp %s %s", file, to))
end

function filesystem.write(name, content)
  local file = io.open(name, "w")
  if file then
    file:write(content)
    file:close()
  end
end

return filesystem
