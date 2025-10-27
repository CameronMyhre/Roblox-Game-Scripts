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

local remoteFunctions = replicatedStorage:WaitForChild("Remote Functions")
local teleportPlrFunction = remoteFunctions:WaitForChild("TeleportPlayerFunction")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local exitQuest = quests:WaitForChild("ExitQuest")
local elevator = exitQuest:WaitForChild("Elevator")

-- Settings --
local completedTag = "fuelQuestFinished"
local placeId = 6970647647
local badgeId = 2147738932

local teleportDistance = 20

-- Functions --
local function teleportPlr(plr: Player)
	
	-- Verify the quest is finished.
	if not collectionService:HasTag(plr, completedTag) then
		return
	end
	
	-- Verify that the player is actually in the elevator.
	if not plr.Character or not plr.Character.PrimaryPart then
		return
	end
	
	local distanceToElevator = (plr.Character.PrimaryPart.CFrame.Position - elevator.PrimaryPart.CFrame.Position).Magnitude
	if distanceToElevator > 20 then
		return
	end
	
	-- Attempt to teleport the player.
	teleportEvent:FireClient(plr)
	
	-- Give the player the badge if they do not have it already.
	if not badgeService:UserHasBadgeAsync(plr.UserId, badgeId) then
		badgeService:AwardBadge(plr.UserId, badgeId)
	end
	
	-- Actually teleport the player.
	task.wait(5)
	teleportService:TeleportAsync(placeId, {plr}, nil)
end

-- Events --
teleportPlrFunction.OnServerInvoke = teleportPlr