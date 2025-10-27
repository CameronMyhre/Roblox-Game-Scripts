-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")
local players = game:GetService("Players")

local teleportService = game:GetService("TeleportService")
local badgeService = game:GetService("BadgeService")

-- Remote Events --
local framework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = framework:WaitForChild("Remote Events")
local teleportEvent = remoteEvents:WaitForChild("TeleportEvent")

-- Objects --
local teleportParts = workspace:WaitForChild("Teleport Parts")
local level15TeleportPart = teleportParts:WaitForChild("Level 15 Teleport Part")
local kylePart = teleportParts:WaitForChild("Kyle Teleport Part")
local kyleSettings = kylePart:WaitForChild("Settings-Kyle")

-- Settings --
local kylePlaceId = 120028929615353
local level15PlaceID = 7370130458

-- Storage --
local teleportingPlrs = {}

-- Functions --
local function teleportPlr(plr: Player, placeID: number, teleportSetting: Configuration?)
	
	-- Verify that the player is alive, and not already teleporting,
	if not plr.Character or not plr.Character.PrimaryPart or table.find(teleportingPlrs, plr) then
		return
	end

	-- The player is teleporting.
	table.insert(teleportingPlrs, plr)

	-- Attempt to teleport the player.
	teleportEvent:FireClient(plr, teleportSetting)
	
	-- Actually teleport the player.
	task.wait(5)
	teleportService:TeleportAsync(placeID, {plr}, nil)
	task.wait(5)
	table.remove(teleportingPlrs, table.find(teleportingPlrs, plr))
end

local function kylePartTouched(part)
	
	-- Verify that the part belongs to a player.
	local plr = players:GetPlayerFromCharacter(part.Parent)
	if not plr then
		return
	end
	
	-- Attempt to teleport the player.
	teleportPlr(plr, kylePlaceId, kyleSettings)
end

local function level15PartTouched(part)
	
	-- Verify that the part belongs to a player.
	local plr = players:GetPlayerFromCharacter(part.Parent)
	if not plr then
		return
	end

	-- Attempt to teleport the player.
	teleportPlr(plr, level15PlaceID)
end

-- Events --
kylePart.Touched:Connect(kylePartTouched)
level15TeleportPart.Touched:Connect(level15PartTouched)