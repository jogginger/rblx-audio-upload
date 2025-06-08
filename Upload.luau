local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Base64 = require("./Lib/Base64")

require("./Lib/dotenv")()

local COOKIE = roblox.getAuthCookie()
local URL = "https://publish.roblox.com/v1/audio"

local Verbose = false 
local TargetGroupId = nil
local SourcePath = "sounds"

for index, arg in process.args do
	if arg == "-v" or arg == "--verbose" then
		Verbose = true
    elseif arg == "-g" or arg == "--group" then 
        TargetGroupId = process.args[index + 2]
    elseif arg == "-s" or arg == "--source" then
        SourcePath = process.args[index + 2]
	end
end

function Log(...)
    if Verbose then 
        print(...)
    end
end

Log("Getting CSRF")

local GetCSRF = net.request({
	url = URL,
	method = "POST",
	headers = {
		["Cookie"] = COOKIE,
		["Content-Type"] = "application/xml",
	},
})

local CSRF = GetCSRF.headers["x-csrf-token"]
if not CSRF then
	error("Wasn't able to get CSRF token")
end

-- uses ffmpeg to retrieve audio length
local function GetAudioDuration(FilePath: string): number?
	local result = process.exec("ffprobe", {
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		FilePath
	})
	if result.ok then
		return tonumber(result.stdout)
	end
	return nil
end

local function Upload(File: string, FileName: string?, Length: number?)
    local res = net.request({
        url = URL,
        method = "POST",
        headers = {
            ["Cookie"] = COOKIE,
            ["Content-Type"] = "application/json",
            ["X-CSRF-TOKEN"] = CSRF,
        },
        body = serde.encode("json", {
            name = FileName or "Audio",
            file = Base64.encode(File),
            groupId = TargetGroupId,
            paymentSource = "User",
            estimatedFileSize = #File,
            estimatedDuration = Length or 7,
            assetPrivacy = 1
        })
    })

    if not res.ok then
        error(`Failed to upload: {res.statusCode} {res.statusMessage} {res.body}`)
    else 
        return serde.decode("json", res.body)
    end
end

local List = ""
local Ids = ""

for _, FileName in fs.readDir(SourcePath) do
    local Path = `{SourcePath}/{FileName}`

    local File = fs.readFile(Path)
    local Length = GetAudioDuration(Path)
    if Length then 
        Length = math.round(Length)
    end

    Log(`Uploading {FileName}, Approx. Length: {Length or "?"}\n`)

    local Body = Upload(File, FileName, Length)
    if Body then 
        List ..= `{FileName:match("^(.*)%.")} - {Body.Id}\n`
        Ids ..= `{Body.Id},`
    end
end

-- Truncating
if string.sub(Ids, #Ids, #Ids) == "," then 
    Ids = string.sub(Ids, 0, #Ids - 1)
end

Log(`{List}\n\n{Ids}`)