-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(0.5, Enum.EasingStyle.Quad)

-- Bindable Events --
local bindableEvents = replicatedStorage:WaitForChild("Bindable Events")
local questBindableEvents = bindableEvents:WaitForChild("Quest")
local toggleControlRoomDoorEvent = questBindableEvents:WaitForChild("ToggleControlRoomDoor")

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local questEvents = remoteEvents:WaitForChild("Quest")
local controlRoomEvents = questEvents:WaitForChild("Control Room")
local flipBreakerEvent = controlRoomEvents:WaitForChild("FlipBreaker")
local resetPuzzleEvent = controlRoomEvents:WaitForChild("ResetPuzzle")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local administrationQuest = quests:WaitForChild("Administration Quest")

-- Settings --
local inactiveLightColor = Color3.fromRGB(255, 85, 85)
local activeLightColor = Color3.fromRGB(119, 255, 98)

local requiredBreakers = 4

-- Storage --
local flippedPowerBoxes = {}

-- Functions --
local function getEmitter(powerBox: Model)
	
	-- Try to find the status light part.
	local statusLight = powerBox:FindFirstChild("StatusLight")
	if not statusLight then
		return
	end
	
	-- Try and find the emitter part and return the result.
	return statusLight:FindFirstChild("Emitter")
end

local function getProximityPromptAndSound(powerBox: Model)
	
	-- Attempt to find the buttons part that contains the interaction point.
	local buttons = powerBox:FindFirstChild("Buttons")
	if not buttons then
		return
	end
	
	-- Attempt to find the sound effect.
	local flipSFX = buttons:FindFirstChild("Flip")
	
	-- Attempt to find the interaction point.
	local interactionPoint = buttons:FindFirstChild("InteractionPoint")
	if not interactionPoint then
		return
	end
	
	-- Attempt to find the proximity prompt and return the result.
	return interactionPoint:FindFirstChild("ProximityPrompt"), flipSFX
end

local function flipSwitch(powerBox: Model)
	
	-- Attempt to find the status light on the power box.
	local statusEmitter = getEmitter(powerBox)
	if not statusEmitter then
		warn("Error: " .. powerBox.Name .. " does not contain an emitter.")
		return
	end
	
	-- Attempt to find the proximity prompt.
	local proximityPrompt, flipSFX: Sound = getProximityPromptAndSound(powerBox)
	if not proximityPrompt then
		warn("Error: " .. powerBox.Name .. " does not contain a ProximityPrompt.")
		return
	end
	
	-- Add the power box to the list of flipped breakers.
	table.insert(flippedPowerBoxes, powerBox)
	
	-- Play the sound effect if present.
	if flipSFX then
		flipSFX.TimePosition = 1.5
		flipSFX:Play()
	end
	
	-- Tween the status light.
	tweenService:Create(statusEmitter, defaultTween, {
		Color = activeLightColor
	}):Play()
	
	-- Toggle the proximity prompt.
	proximityPrompt.Enabled = false
	
	-- If enough breakers have been flipped, open the door.
	if #flippedPowerBoxes >= requiredBreakers then
		toggleControlRoomDoorEvent:Fire(true)
	end
end

local function resetPuzzle()
	
	-- Deactivate all of the breakers.
	for _, powerBox in ipairs(flippedPowerBoxes) do
		
		local statusEmitter = getEmitter(powerBox)
		local proximityPrompt = getProximityPromptAndSound(powerBox)
		
		-- Tween the light back to red. This is done as opposed to just setting the color to auto cancel the tween.
		tweenService:Create(statusEmitter, defaultTween, {
			Color = inactiveLightColor
		}):Play()
		
		-- Toggle the proximity prompt.
		proximityPrompt.Enabled = true
	end
	
	-- Clear out the flipped power boxes.
	table.clear(flippedPowerBoxes)
	
	-- Lock the control room.
	toggleControlRoomDoorEvent:Fire(false)
end

-- Events --
flipBreakerEvent.OnClientEvent:Connect(flipSwitch)
resetPuzzleEvent.OnClientEvent:Connect(resetPuzzle)