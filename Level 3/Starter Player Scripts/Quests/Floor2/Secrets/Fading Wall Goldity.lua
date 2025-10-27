-- Services --
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(2, Enum.EasingStyle.Quad)

local replicatedStorage = game:GetService("ReplicatedStorage")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local bloodlustEvents = remoteEvents:WaitForChild("Bloodlust")
local openDaDoorEvent = bloodlustEvents:WaitForChild("OpenDaDoor")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local fadingWallQuest = quests:WaitForChild("Hidden Area - Goldity")
local hiddenWall = fadingWallQuest:WaitForChild("DoorModel")
local door = hiddenWall:WaitForChild("Door")
local proximityPrompt = door:WaitForChild("ProximityPrompt")
	
-- Flags --
local isDoorOpen = false

-- Functions --
local function fadeWall()
	
	-- Fade Wall --
	hiddenWall:Destroy()
end

local function promptTriggered(plr: Player)
	
	-- If the player who triggered the prompt isn't the local player, then return.
	if plr ~= localPlr or not isDoorOpen then
		return
	end
	
	fadeWall()
end

local function toggleDoorOpen()
	isDoorOpen = true
	task.wait(180)
	isDoorOpen = false
end

-- Events --
proximityPrompt.Triggered:Connect(promptTriggered)
openDaDoorEvent.OnClientEvent:Connect(toggleDoorOpen)