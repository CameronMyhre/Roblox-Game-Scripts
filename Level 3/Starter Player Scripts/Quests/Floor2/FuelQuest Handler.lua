-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local fuelPlacedEvent = remoteEvents:WaitForChild("FuelPlacedEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local fuelQuest = quests:WaitForChild("Fuel Quest")

local interactionContainer = fuelQuest:WaitForChild("InteractionContainer")
local interactionPoint = interactionContainer:WaitForChild("InteractionPoint")
local interactionPrompt = interactionPoint:WaitForChild("ProximityPrompt")

local voidstoneFuelCellPlaced = fuelQuest:WaitForChild("Voidstone Fuel Cell (Placed)")
local core = voidstoneFuelCellPlaced:WaitForChild("Core")
local shell = voidstoneFuelCellPlaced:WaitForChild("Shell")
local cage = voidstoneFuelCellPlaced:WaitForChild("Cage")

local exitQuest = quests:WaitForChild("ExitQuest")
local questProgress = exitQuest:WaitForChild("Progress")

-- Functions --
local function onFuelPlaced()
	
	-- The fuel cell has been added to the pedestal.
	questProgress:SetAttribute("fuelAdded", true)
	interactionPrompt.Enabled = false -- Disable the prompt.
	
	-- Show the voidstone fuel canister placed.
	tweenService:Create(core, defaultTween, {
		Transparency = 0
	}):Play()
	
	tweenService:Create(cage, defaultTween, {
		Transparency = 0
	}):Play()
	
	tweenService:Create(shell, defaultTween, {
		Transparency = 0.8
	}):Play()
	
	-- Disable the script after the tweens.
	task.wait(defaultTween.Time)
	script.Enabled = false
end

-- Events --
fuelPlacedEvent.OnClientEvent:Connect(onFuelPlaced)