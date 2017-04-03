local shell = {}

function shell.execute(command)
	local handle = io.popen(command .. " 2>&1")
	local data = handle:read("*a")
	handle:close()

	return data
end

return shell