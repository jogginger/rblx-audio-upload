local fs = require("@lune/fs")
local process = require("@lune/process")

local function LoadEnvFile(Path: string)
	for _, Line in fs.readFile(Path):split("\n") do
		local Key, Value = Line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
		if Key and Value then
			process.env[Key] = Value
		end
	end
end

return function(PathOverwrite: string?)
    LoadEnvFile(PathOverwrite or ".env")
end
