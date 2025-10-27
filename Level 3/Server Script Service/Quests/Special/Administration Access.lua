-- Services --
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local collectionService = game:GetService("CollectionService")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local questEvents = remoteEvents:WaitForChild("Quest")
local controlRoomEvents = questEvents:WaitForChild("Control Room")
local flipBreakerEvent = controlRoomEvents:WaitForChild("FlipBreaker")
local resetPuzzleEvent = controlRoomEvents:WaitForChild("ResetPuzzle")

local framework = replicatedStorage:WaitForChild("Framework")
local frameworkRemoteEvents = framework:WaitForChild("Remote Events")
local dialogEvents = frameworkRemoteEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local administrationQuest = quests:WaitForChild("Administration Quest")
local powerBoxes = administrationQuest:WaitForChild("Power Boxes")

-- Settings --
local requiredPowerBoxes = 4
local dialogBase = "~!~SmallWave~%s/%s Breakers Flipped~"
local resetDialog = "~!~SlowFade~The breakers flip back into place.~"

local administrationTag = "ControlRoomUnlocked"

-- Storage --
local playerProgress = {}

-- Functions --
local function powerBoxActivated(plr, powerBox)
	
	-- If the player has no data, create it for them.
	if not playerProgress[plr] then
		playerProgress[plr] = {}
	end
	
	-- If the player already flipped this switch, return.
	if table.find(playerProgress[plr], powerBox) then
		return
	end
	
	-- Add this power box to the player's flipped power box list.
	table.insert(playerProgress[plr], powerBox)
	
	-- Handle dialog.
	local numBreakersFlipped = #playerProgress[plr]
	local dialog = string.format(dialogBase, numBreakersFlipped, requiredPowerBoxes)
	dialogEvent:FireClient(plr, dialog, Enum.Font.Gotham, 2, 1, true)

	-- This power box has now been flipped.
	flipBreakerEvent:FireClient(plr, powerBox)
	
	-- If the player has flipped all of the breaker boxes, then tag their character using collections.
	if numBreakersFlipped >= requiredPowerBoxes then

		local character = plr.Character
		if not character then
			return
		end

		-- Tag the character so other scripts can listen in.
		collectionService:AddTag(character, administrationTag)
	end
end

local function setup()
	
	-- Setup events for all of the power boxes.
	for _, powerBox in ipairs(powerBoxes:GetChildren()) do
		
		-- Get necessary parts.
		local buttons = powerBox:FindFirstChild("Buttons")
		local interactionPoint = buttons:FindFirstChild("InteractionPoint")
		local proximityPrompt = interactionPoint:FindFirstChild("ProximityPrompt")
		
		-- Setup events.
		proximityPrompt.Triggered:Connect(function (plr)
			powerBoxActivated(plr, powerBox)
		end)
	end
end

-- Event Functions --
local function clearPlrData(plr)
	
	-- Clear the player's progress on death.
	if playerProgress[plr] and #playerProgress[plr] > 0 then
		table.clear(playerProgress[plr])
		resetPuzzleEvent:FireClient(plr)
		dialogEvent:FireClient(plr, resetDialog, Enum.Font.Gotham, 2, 1, true)
	end
end

local function plrAdded(plr: Player)
	
	-- Setup player data.
	playerProgress[plr] = {}
	
	-- Clear data on death.
	plr.CharacterAdded:Connect(function ()
		clearPlrData(plr)
	end)
end

local function plrRemoving(plr)
	
	-- Remove data if present.
	playerProgress[plr] = nil
end

-- Events --
players.PlayerAdded:Connect(plrAdded)
players.PlayerRemoving:Connect(plrRemoving)

-- Setup.
setup()