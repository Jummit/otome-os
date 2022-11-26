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
	local f = io.open(file)
	if not f then return "" end
	local lines = {}
	for line in f:read("a"):gmatch("[^\n]+") do
		table.insert(lines, line)
	end
	return lines
end

function filesystem.move(file, to)
  os.execute(string.format("mv %s %s", file, to))
end

function filesystem.copy(file, to)
  os.execute(string.format("cp %s %s", file, to))
end

return filesystem
