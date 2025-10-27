-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)
local doorTween = TweenInfo.new(2, Enum.EasingStyle.Quad)

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local dialogEvents = bindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

-- Remote Functions --
local remoteFunctions = replicatedStorage:WaitForChild("Remote Functions")
local teleportPlrFunction = remoteFunctions:WaitForChild("TeleportPlayerFunction")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local exitQuestFolder = quests:WaitForChild("ExitQuest")
local elevator = exitQuestFolder:WaitForChild("Elevator")

local leftDoor = elevator:WaitForChild("LeftDoor")
local rightDoor = elevator:WaitForChild("RightDoor")

local outerpanel = elevator:WaitForChild("Outerpanel")
local outerCore = outerpanel:WaitForChild("main")
local outerPromptContainer = outerCore:WaitForChild("Prompt")
local outerProximityPrompt = outerPromptContainer:WaitForChild("ProximityPrompt")

local innerpanel = elevator:WaitForChild("Innerpanel")
local innerCore = innerpanel:WaitForChild("main")
local innerPromptContainer = innerCore:WaitForChild("Prompt")
local innerProximityPrompt = innerPromptContainer:WaitForChild("ProximityPrompt")

local progress = exitQuestFolder:WaitForChild("Progress")

-- SFX --
local doorSFX = leftDoor:WaitForChild("open/close")
local dingSFX = outerCore:WaitForChild("ding")

---- Settings ----
local callButtonColor = Color3.fromRGB(255, 173, 105)

local additionalDoorToggleDelay = 2 -- Seconds.
local elevatorCallTime = 3 -- Seconds
local buttonPlayTime = 1

local requiredGenerators = 3

local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {quests}

local bothMissingDialog = "~!~Fade~The generators sit idle. Water must be rerouted to their cooling systems… and a voidstone power cell must be installed before they will awaken.~"
local coolantMissingDialog = "~!~Fade~The generators hum faintly, but their cooling systems are dry. Redirect water to them.~"
local powerCellMissingDialog = "~!~Fade~The generators are cold and lifeless. Insert a voidstone power cell to bring them online.~"

local fuelAddedDialog = "~!~SlowFade,Delay~The generators stand idle, requiring coolant to start once again.~"
local coolantAddedDialog = "~!~SlowFade,Delay~The generators hum as the water flows through them, readily awaiting fuel.~"

local fuelAddedPuzzleFinishDialog = "~!~SlowFade,Delay~As the fuel canister snaps into place, Level 3's generators hum once again, and the elevator roars to life.~"
local coolantAddedPuzzleFinishedDialog = "~!~SlowFade,Delay~As the last pipe turns into place, water surges through the pipes towards the generators. The generators hum as the elevator roars to life.~"
-- Flags --
local hasFuel = false
local coolantPresent = false
local debounce = false
local isOpen = false

-- Functions --
local function toggleDoors(leftDoor: Part, rightDoor: Part, doorSound: Sound, isClosing: boolean)

	-- Get the target positions for each door.
	local leftTargetPose, rightTargetPose
	if isClosing then
		leftTargetPose = leftDoor:GetAttribute("DefaultPos")
		rightTargetPose = rightDoor:GetAttribute("DefaultPos")
	else
		leftTargetPose = leftDoor:GetAttribute("OpenPos")
		rightTargetPose = rightDoor:GetAttribute("OpenPos")
	end

	-- Play the door sound.
	doorSound:Play()

	-- Tween the doors into position.
	tweenService:Create(leftDoor, doorTween, {
		CFrame = leftTargetPose
	}):Play()
	tweenService:Create(rightDoor, doorTween, {
		CFrame = rightTargetPose
	}):Play()

	-- Wait for the tweens to complete.
	task.wait(doorTween.Time + additionalDoorToggleDelay)
end

local function callElevator(panel: Model, isGoingUp: boolean, dingSFX: Sound?)

	local activeButton
	if isGoingUp then
		activeButton = panel:FindFirstChild("Up")
	else
		activeButton = panel:FindFirstChild("Down")
	end

	if not activeButton then
		warn("Error: Incompatible panel object thrown in elevator script.")
		return
	end

	-- Change the button color. Then, after the elevator appears, change it back.
	tweenService:Create(activeButton, defaultTween, {
		Color = callButtonColor
	}):Play()

	task.wait(buttonPlayTime)

	-- Play a ding sound if told to do so.
	if dingSFX then
		dingSFX:Play()
	end

	task.wait(elevatorCallTime - buttonPlayTime)

	tweenService:Create(activeButton, defaultTween, {
		Color = Color3.fromRGB(0, 0, 0)
	}):Play()
end

-- Prompt Triggering Options --
local function playMissingItemDialog()
	
	if not hasFuel and not coolantPresent then
		dialogEvent:Fire(bothMissingDialog, Enum.Font.Gotham, 4)
	end
	
	if not hasFuel then
		dialogEvent:Fire(powerCellMissingDialog, Enum.Font.Gotham, 3)
	else
		dialogEvent:Fire(coolantMissingDialog, Enum.Font.Gotham, 3)
	end
end

local function promptTriggered(plr: Player, isOuter: boolean)

	-- Make sure that the quest is compelted.
	if not hasFuel or not coolantPresent then
		playMissingItemDialog()
		return
	end
	
	-- Return if the prompt is triggered by another player.
	if plr ~= localPlayer or debounce then
		return
	end

	-- Handle trying to reopen the door from the outside when the door is already open.
	if isOuter and isOpen then
		return
	end 

	-- Toggle debounce.
	debounce = true

	-- If the inner panel is used and the door is open, then close the door and attempt to teleport the player.
	if isOuter and not isOpen then
		
		-- Toggle is open.
		isOpen = true
		
		-- Dissable the external proximity prompts.
		outerProximityPrompt.Enabled = false

		callElevator(outerpanel, true, dingSFX)
		toggleDoors(leftDoor, rightDoor, doorSFX, false)

		-- Toggle the factory proximity prompts.
		innerProximityPrompt.Enabled = true
		outerProximityPrompt.Enabled = true
	end

	-- If the inner panel is used and the door is open, then close the door and attempt to teleport the player.
	if not isOuter and isOpen then

		-- Toggle the interior proximity prompts.
		innerProximityPrompt.Enabled = false
		
		isOpen = false
		toggleDoors(leftDoor, rightDoor, doorSFX, true)
		callElevator(innerpanel, false)

		-- Attempt to teleport the player to the next area.
		task.wait(defaultTween.Time)
		teleportPlrFunction:InvokeServer()
		
		-- Open the doors if the teleport failed.
		task.wait(3)
		toggleDoors(leftDoor, rightDoor, doorSFX, false)
		innerProximityPrompt.Enabled = true
	end

	-- Toggle debounce.
	debounce = false
end

local function innerPromptTriggerd(plr: Player)
	promptTriggered(plr, false)
end

local function outerPromptTriggered(plr: Player)
	promptTriggered(plr, true)
end

-- Attribute Update Functions --
local function attributeChanged(attributeName: string)
	
	if attributeName == "PipesAligned" then
		coolantPresent = true
		
		-- Play dialog based on what else was completed.
		if hasFuel then
			dialogEvent:Fire(coolantAddedPuzzleFinishedDialog, Enum.Font.Gotham, 3)
		else
			dialogEvent:Fire(coolantAddedDialog, Enum.Font.Gotham, 3)
		end
	end
	
	if attributeName == "fuelAdded" then
		hasFuel = true
		
		-- Play dialog based on what else was completed.
		if coolantPresent then
			dialogEvent:Fire(fuelAddedPuzzleFinishDialog, Enum.Font.Gotham, 3)
		else
			dialogEvent:Fire(fuelAddedDialog, Enum.Font.Gotham, 3)
		end
	end
end

-- Events --
progress.AttributeChanged:Connect(attributeChanged)
outerProximityPrompt.Triggered:Connect(outerPromptTriggered)
innerProximityPrompt.Triggered:Connect(innerPromptTriggerd)