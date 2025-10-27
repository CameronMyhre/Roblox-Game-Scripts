--[[
This script configures the properties of the place to ensure I don't have to spend 20~30 minutes of my life going through each
place and configuring things like the text chat service, player name display distances, first person, etc.

In other words, this configures dependencies for the framework and applies settings we wish to use across all places.

- Lolbit757575
]]

-- Services --
local starterPlayer = game:GetService("StarterPlayer")
local players = game:GetService("Players")

-- Functions --
local function setupPlayer(player: Player)
	
	-- Configure player settings.
	player.NameDisplayDistance = 0
	player.HealthDisplayDistance = 0
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

local function setup()
	
	-- Setup all starter player settings.
	starterPlayer.NameDisplayDistance = 0
	starterPlayer.HealthDisplayDistance = 0
	starterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	
	-- Configure all players who are already in the game.
	for _, player in ipairs(players:GetPlayers()) do
		setupPlayer(player)
	end
end

-- Run the setup function.
setup()