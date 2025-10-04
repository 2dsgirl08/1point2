-- Script `loader.lua`
-- Loader script for 1p2

-- @ constants

local ADDRESS = getgenv().ADDRESS or game:HttpGet("https://raw.githubusercontent.com/2dsgirl08/1point2/refs/heads/main/address.txt"):match("^%s*(.-)%s*$")
local SOCKET = WebSocket.connect("wss://" .. ADDRESS .. "/ws")

-- @ services

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- @ variables

local Player = Players.LocalPlayer

-- @ main

xpcall(function()
	local response = request({
		Url = "https://" .. ADDRESS .. "/hwid",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({key = getgenv().SCRIPT_KEY})
	})

	if response.StatusCode ~= 200 then
		SOCKET:Close()
		return Player:Kick("[1p2] failed first handshake (invalid key?)")
	end

	local body = HttpService:JSONDecode(response.Body)
	local challenge = body["challenge"]

	SOCKET:Send(HttpService:JSONEncode({
		key = getgenv().SCRIPT_KEY,
		challenge = challenge
	}))

	local scriptContent = ""

	SOCKET.OnMessage:Connect(function(content)
		scriptContent = content
	end) -- fuck emu exploits SHITTY websocket library

	local timeout = os.clock()

	while scriptContent == "" and (os.clock() - timeout) < 15 do
		task.wait()
	end

	if scriptContent == "INVALID_HWID" then
		return Player:Kick("[1p2] hwid difference (contact devs)")
	end

	if scriptContent == "" then
		return Player:Kick("[1p2] failed second handshake (tampering, failed to pass challenge)")
	end

	loadstring(scriptContent)()(SOCKET, challenge)
end, function(err)
	warn(err)
	SOCKET:Close()

	return Player:Kick("[1p2] unexpected computation error", err)
end)
