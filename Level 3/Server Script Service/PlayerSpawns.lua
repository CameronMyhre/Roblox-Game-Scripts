-- Services --
local players = game:GetService("Players")

-- Objects --
local invisibleWalls = workspace:WaitForChild("Invisible Parts")
local spawnChangeParts = invisibleWalls:WaitForChild("Spawn Change Triggers")
local toFactoryTriggers = spawnChangeParts:WaitForChild("ToFactory")
local toStationTriggers = spawnChangeParts:WaitForChild("ToStation")
local toAdminSpawnChangeTriggers = spawnChangeParts:WaitForChild("ToAdmin")

local spawns = invisibleWalls:WaitForChild("SpawnLocations")
local factorySpawn = spawns:WaitForChild("Factory Spawn")
local stationSpawn = spawns:WaitForChild("Station Spawn")
local adminSpawn = spawns:WaitForChild("Admin Spawn")

local defaultSpawn = workspace:WaitForChild("SpawnLocation")

-- Functions --
local function partTouched(part, spawn)
	
	local character = part.Parent
	local possiblePlr = game.Players:GetPlayerFromCharacter(character)
	
	if possiblePlr then
		possiblePlr.RespawnLocation = spawn
	end
end

local function playerAdded(plr)
	plr.RespawnLocation = defaultSpawn
end

-- Events --
players.PlayerAdded:Connect(playerAdded)

-- Setup --
for _, trigger in ipairs(toFactoryTriggers:GetChildren()) do
	trigger.Touched:Connect(function (part)
		partTouched(part, factorySpawn)
	end)
end

for _, trigger in ipairs(toStationTriggers:GetChildren()) do
	trigger.Touched:Connect(function (part)
		partTouched(part, stationSpawn)
	end)
end

for _, trigger in ipairs(toAdminSpawnChangeTriggers:GetChildren()) do
	trigger.Touched:Connect(function (part)
		partTouched(part, adminSpawn)
	end)
end