---- Services ----
local replicatedStorage = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)
local doorTween = TweenInfo.new(2, Enum.EasingStyle.Quad)

local players = game:GetService("Players")
local localPlr = players.LocalPlayer

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local dialogEvents = bindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

---- Camera ----
local camera = workspace.CurrentCamera

---- Objects ----
local quests = workspace:WaitForChild("Quests")
local elevatorQuest = quests:WaitForChild("Elevator")

local questProgress = elevatorQuest:WaitForChild("Progress")

-- Factory --
local elevatorFactory = elevatorQuest:WaitForChild("Elevator 1")
local leftFactoryDoor = elevatorFactory:WaitForChild("LeftDoor")
local rightFactoryDoor = elevatorFactory:WaitForChild("RightDoor")
local factoryHitbox = elevatorFactory:WaitForChild("Hitbox")

local factoryOuterpanel = elevatorFactory:WaitForChild("Outerpanel")
local factoryOuterPrompt = factoryOuterpanel:WaitForChild("main"):WaitForChild("Prompt"):WaitForChild("ProximityPrompt")

local factoryInnerpanel = elevatorFactory:WaitForChild("Innerpanel")
local factoryInnerPrompt = factoryInnerpanel:WaitForChild("main"):WaitForChild("Prompt"):WaitForChild("ProximityPrompt")

-- Station --
local elevatorStation = elevatorQuest:WaitForChild("Elevator 2")
local leftStationDoor = elevatorStation:WaitForChild("LeftDoor")
local rightStationDoor = elevatorStation:WaitForChild("RightDoor")
local stationHitbox = elevatorStation:WaitForChild("Hitbox")

local stationOuterpanel = elevatorStation:WaitForChild("Outerpanel")
local stationOuterPrompt = stationOuterpanel:WaitForChild("main"):WaitForChild("Prompt"):WaitForChild("ProximityPrompt")

local stationInnerpanel = elevatorStation:WaitForChild("Innerpanel")
local stationInnerPrompt = stationInnerpanel:WaitForChild("main"):WaitForChild("Prompt"):WaitForChild("ProximityPrompt")

---- SFX ----
local factoryDingSFX = factoryOuterpanel:WaitForChild("main"):WaitForChild("ding")
local stationDingSFX = stationOuterpanel:WaitForChild("main"):WaitForChild("ding")

local factoryDoorSFX = leftFactoryDoor:WaitForChild("open/close")
local stationDoorSFX = leftStationDoor:WaitForChild("open/close")

---- Settings ----
local unlockDialog = "~!~Fade~The elevator rumbles to life.~"
local failBoth = "~!~Fade~The elevator stands silent-no power flows, and a remote lock binds it shut.~"
local failPower = "~!~Fade~The elevator's mechanisms are cold and lifeless. Perhaps there's a way to restore power?~"
local failLock = "~!~Fade~A remote lock holds the elevator in place. Something in the office might release it.~"

local dialogFont = Enum.Font.Gotham
local dialogDuration = 3 -- Seconds

local callButtonColor = Color3.fromRGB(255, 173, 105)

local additionalDoorToggleDelay = 2 -- Seconds.
local elevatorCallTime = 3 -- Seconds
local buttonPlayTime = 1

local requiredGenerators = 3
local hintCooldown = 4

local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {quests}

---- Flags ----
local factoryIsOpen = false
local stationIsOpen = false
local activated = false
local debounce = false

local generatorsPowered = false
local securityDisabled = false
local hintDebounce = false

---- Functions ----
local function teleport(fromElevatorHitbox: BasePart, toElevatorHitbox: BasePart): boolean
	
	-- Get the player's character and their humanoid root part.
	local character = localPlr.Character
	local humanoidRootPart: Part = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("Error: Elevator could not find the root part of the player. Teleport failed.")
		return false
	end
	
	-- Get all overlapping parts inside of the hitbox. If the player isn't inside of the elevator, don't teleport them.
	local overlappingParts = workspace:GetPartBoundsInBox(fromElevatorHitbox.CFrame, fromElevatorHitbox.Size, overlapParams)
	if not table.find(overlappingParts, humanoidRootPart) then
		return false
	end
	
	-- Rotate the player's camera.
	local pivot = CFrame.new(camera.CFrame.Position)
	local offset = pivot:ToObjectSpace(camera.CFrame)
	pivot = pivot * CFrame.Angles(0, math.rad(180), 0)
	camera.CFrame = pivot * offset
	
	-- Get the player's relative position to the from elevator's hitbox.
	local relativeCFrame = fromElevatorHitbox.CFrame:ToObjectSpace(humanoidRootPart.CFrame)
	
	-- Convert the relative CFrame to the to elevator's hitbox's cframe.
	local targetCFrame = toElevatorHitbox.CFrame:ToWorldSpace(relativeCFrame)
	
	-- Teleport the player.
	humanoidRootPart.CFrame = targetCFrame
	
	-- The operation was successful.
	return true
end

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

local function playHintDialog()
	
	-- Toggle hint debounce.
	hintDebounce = true
	
	-- Display the appropriate dialog.
	if not generatorsPowered and not securityDisabled then
		dialogEvent:Fire(failBoth, dialogFont, dialogDuration, true)
	elseif not generatorsPowered then
		dialogEvent:Fire(failPower, dialogFont, dialogDuration, true)
	else
		dialogEvent:Fire(failLock, dialogFont, dialogDuration, true)
	end
	
	-- Toggle hint debounce.
	task.wait(hintCooldown)
	hintDebounce = false
end

local function promptTriggered(plr: Player, isFactory: boolean, isOuter: boolean)
	
	-- Only allow elevator travel if the quest has been completed.
	if not activated then
		
		if not hintDebounce then
			playHintDialog()
		end
		return
	end
	
	-- Return if the prompt is triggered by another player.
	if plr ~= localPlr or debounce then
		return
	end

	-- Handle trying to reopen the door from the outside when the door is already open.
	if isOuter and (isFactory and factoryIsOpen or not isFactory and stationIsOpen) then
		return
	end
	
	-- Toggle debounce.
	debounce = true
	
	-- If the inner panel is used and the door is open, then close the door and attempt to teleport the player.
	if isOuter and (isFactory and not factoryIsOpen or not isFactory and not stationIsOpen) then
		
		-- Close the respective door.
		if isFactory then
			factoryIsOpen = true
			
			-- Disable the external proximity prompts.
			factoryOuterPrompt.Enabled = false
			
			callElevator(factoryOuterpanel, true, factoryDingSFX)
			toggleDoors(leftFactoryDoor, rightFactoryDoor, factoryDoorSFX, false)

			-- Toggle the factory proximity prompts.
			factoryInnerPrompt.Enabled = true
			factoryOuterPrompt.Enabled = true
		else
			stationIsOpen = true
			
			-- Disable the external proximity prompts.
			stationOuterPrompt.Enabled = false

			callElevator(factoryOuterpanel, false, stationDingSFX)
			toggleDoors(leftStationDoor, rightStationDoor, stationDoorSFX, false)

			-- Toggle the station proximity prompts.
			stationInnerPrompt.Enabled = true
			stationOuterPrompt.Enabled = true
		end
	end
	
	-- If the inner panel is used and the door is open, then close the door and attempt to teleport the player.
	if not isOuter and (isFactory and factoryIsOpen or not isFactory and stationIsOpen) then
	
		-- Toggle the interior proximity prompts.
		factoryInnerPrompt.Enabled = false
		stationInnerPrompt.Enabled = false
		
		-- Close the respective door.
		if isFactory then
			factoryIsOpen = false
			toggleDoors(leftFactoryDoor, rightFactoryDoor, factoryDoorSFX, true)
			callElevator(factoryInnerpanel, false)

			-- Load in the area the player will be teleported to.
			localPlr:RequestStreamAroundAsync(stationHitbox.Position)
			
			-- Attempt to teleport the player to the next area.
			task.wait(defaultTween.Time)
			local success = teleport(factoryHitbox, stationHitbox)
			if success then
				
				-- Toggle the station's doors.
				stationIsOpen = true
				
				-- Toggle the doors and play a ding sound.
				stationDingSFX:Play()
				task.wait(elevatorCallTime - buttonPlayTime)
				toggleDoors(leftStationDoor, rightStationDoor, stationDoorSFX, false)

				-- Toggle the station proximity prompt.
				stationInnerPrompt.Enabled = true
			else
				factoryInnerPrompt.Enabled = true
			end
		else
			stationIsOpen = false
			toggleDoors(leftStationDoor, rightStationDoor, stationDoorSFX, true)
			callElevator(stationInnerpanel, true)

			-- Load in the area the player will be teleported to.
			localPlr:RequestStreamAroundAsync(factoryHitbox.Position)
			
			-- Attempt to teleport the player to the next area.			
			task.wait(defaultTween.Time)
			local success = teleport(stationHitbox, factoryHitbox)
			if success then
				
				-- Toggle the factory's doors.
				factoryIsOpen = true
				
				-- Toggle the doors and play a ding sound.
				factoryDingSFX:Play()
				task.wait(elevatorCallTime - buttonPlayTime)
				toggleDoors(leftFactoryDoor, rightFactoryDoor, factoryDoorSFX, false)

				-- Toggle the factory proximity prompt.
				factoryInnerPrompt.Enabled = true
			else
				stationInnerPrompt.Enabled = true
			end
		end
	end
	
	-- Toggle debounce.
	debounce = false
end

-- Factory --
local function outerPromptTriggeredFactory(plr)
	promptTriggered(plr, true, true)
end
local function innerPromptTriggeredFactory(plr)
	promptTriggered(plr, true, false)
end

-- Station --
local function outerPromptTriggeredStation(plr)
	promptTriggered(plr, false, true)
end
local function innerPromptTriggeredStation(plr)
	promptTriggered(plr, false, false)
end

-- Progress Events --
local function attributeChanged(attributeName: string)
	
	-- Update values accordingly.
	if attributeName == "GeneratorsActive" then
		generatorsPowered = questProgress:GetAttribute("GeneratorsActive") >= requiredGenerators
	elseif attributeName == "LockDisabled" then
		securityDisabled = true
	end
	
	-- Active the elevator if both checks pass.
	if generatorsPowered and securityDisabled then
		activated = true
		dialogEvent:Fire(unlockDialog, dialogFont, dialogDuration, true)
	end
end

---- Events ----
factoryOuterPrompt.Triggered:Connect(outerPromptTriggeredFactory)
factoryInnerPrompt.Triggered:Connect(innerPromptTriggeredFactory)

stationOuterPrompt.Triggered:Connect(outerPromptTriggeredStation)
stationInnerPrompt.Triggered:Connect(innerPromptTriggeredStation)

questProgress.AttributeChanged:Connect(attributeChanged)