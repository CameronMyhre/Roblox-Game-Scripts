-- Services --
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local localPlr = players.LocalPlayer

local tweenService = game:GetService("TweenService")
local guiFadeTween = TweenInfo.new(.5, Enum.EasingStyle.Quad)
local slowFade = TweenInfo.new(.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local quickTween = TweenInfo.new(.2, Enum.EasingStyle.Quad)

-- Modules --
local framework = replicatedStorage:WaitForChild("Framework")
local modules = framework:WaitForChild("Modules")
local enums = modules:WaitForChild("Enums")
local movementStateEnum = require(enums:WaitForChild("MovementState"))

local controls = require(localPlr.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

-- Remote Events --
local remoteEvents = replicatedStorage:WaitForChild("Remote Events")
local controlRoomEvents = remoteEvents:WaitForChild("ControlRoom")
local activateEventEvent = controlRoomEvents:WaitForChild("ActivateEvent")
local eventDataUpdatedEvent = controlRoomEvents:WaitForChild("EventDataUpdated")

local frameworkRemoteEvents = framework:WaitForChild("Remote Events")
local playerEvents = frameworkRemoteEvents:WaitForChild("Player")
local deathEvent = playerEvents:WaitForChild("DeathEvent")

-- Remote Functions --
local remoteFunctions = replicatedStorage:WaitForChild("Remote Functions")
local getEventDataFunction = remoteFunctions:WaitForChild("GetAllEventData")

-- Bindable Events --
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

local dialogEvents = bindableEvents:WaitForChild("DialogEvents")
local dialogEvent = dialogEvents:WaitForChild("DialogEvent")

local vfxBindableEvents = bindableEvents:WaitForChild("VFX")
local toggleVFXBindableEvent = vfxBindableEvents:WaitForChild("ToggleVFX")

local movementBindableEvents = bindableEvents:WaitForChild("Movement")
local forceStateBindableEvent = movementBindableEvents:WaitForChild("ForceMovementStateEvent")

-- Objects --
local quests = workspace:WaitForChild("Quests")
local controlRoomQuest = quests:WaitForChild("Control Room Quest")
local cameraPart = controlRoomQuest:WaitForChild("CameraPose")

local triggerPart = controlRoomQuest:WaitForChild("TriggerPart")
local trigger = triggerPart:WaitForChild("ProximityPrompt")

local camera = workspace.CurrentCamera

-- GUI --
local controlRoomTerminal = controlRoomQuest:WaitForChild("Screen")

local gui = controlRoomTerminal:WaitForChild("SurfaceGui")
local terminalScreen = gui:WaitForChild("Terminal Screen")
local terminalContainer = terminalScreen:WaitForChild("ScrollingFrame")
local terminalInput = terminalContainer:WaitForChild("Input")

local eventSelection = gui:WaitForChild("EventSelection")
local dayEvents = eventSelection:WaitForChild("day")
local nightEvents = eventSelection:WaitForChild("night")
local anyEvents = eventSelection:WaitForChild("any")

local generalInfo = eventSelection:WaitForChild("General Info")
local serverCooldownText = generalInfo:WaitForChild("Cooldown")

local closeButtonContainer = gui:WaitForChild("CloseButton")
local closeButton = closeButtonContainer:WaitForChild("Button")

-- Settings --
local defaultTextColor = Color3.fromRGB(0, 255, 51)
local hoverTextColor = Color3.fromRGB(87, 255, 93)

local canUseStatusText = "Ready"
local cannotUseStatusText = "On Cooldown"
local cooldownText = "Server Cooldown: [%ss]"

local updateTime = 0.25 -- Seconds

-- Flags --
local grabbedData = false

-- Storage --
local oldCameraCFrame
local character

local givenEventData = {}
local eventData = {}

local serverCooldown
local remainingServerCooldown

local accumulatedTime = 0

-- Functions --
-- GUI Functions --
local function toggleMouseHover(button: GuiButton, shouldShowEffects: boolean)
	
	local targetColor = defaultTextColor
	if shouldShowEffects then
		targetColor = hoverTextColor
	end
	
	-- Find all the relevant GUI elements and tween them.
	local cooldownText = button:FindFirstChild("Cooldown")
	local statusText = button:FindFirstChild("Status")
	local titleText = button:FindFirstChild("Title")
	if cooldownText and statusText and titleText then
		
		tweenService:Create(cooldownText, quickTween, {
			TextColor3 = targetColor
		}):Play()
		
		tweenService:Create(statusText, quickTween, {
			TextColor3 = targetColor
		}):Play()
		
		tweenService:Create(titleText, quickTween, {
			TextColor3 = targetColor
		}):Play()
	end
end

local function updateServerCooldownGUI()
	
	-- Update the server cooldown text.
	local newCooldownText = string.format(cooldownText, math.ceil(remainingServerCooldown))
	
	-- Update the text.
	serverCooldownText.Text = newCooldownText
end


local function updateGUIInformation(button: GuiButton, currentCooldown: number)
	
	-- Update the GUI elements.
	local cooldownText = button:FindFirstChild("Cooldown")
	if cooldownText then
		cooldownText.Text = math.ceil(currentCooldown)
	end

	local statusText = button:FindFirstChild("Status")
	if cooldownText then

		local newStatusText = canUseStatusText
		if currentCooldown > 0 then
			newStatusText = cannotUseStatusText
		end
		statusText.Text = newStatusText
	end
end

-- Setup Updates --
local function setupEventGUIFromData()
	
	-- Reformat the event data to contain a reference to the button GUI element.
	local newEventData = {}
	
	-- Go through all of the events and add the button to the data.
	for _, data in ipairs(givenEventData) do
		
		-- Get the container for the button.
		local dataContainer
		if data.eventType == "day" then
			dataContainer = dayEvents
		elseif data.eventType == "night" then
			dataContainer = nightEvents
		else
			dataContainer = anyEvents
		end
		
		-- Attempt to find the respective button.
		local possibleButton: GuiButton = dataContainer:FindFirstChild(data.eventName)
		if not possibleButton then
			warn("No button found in [" .. data.eventType .. "] with name [" .. data.eventName .. "].")
			continue
		end
		
		-- Handle hover effects.
		possibleButton.MouseEnter:Connect(function ()
			toggleMouseHover(possibleButton, true)
		end)
		
		possibleButton.MouseLeave:Connect(function ()
			toggleMouseHover(possibleButton, false)
		end)
		
		local eventName = data.eventName
		possibleButton.Activated:Connect(function ()
			activateEventEvent:FireServer(eventName)
		end)
		
		-- Update the GUI elements.
		updateGUIInformation(possibleButton, data.currentCooldown)
		
		-- Add the button to the data.
		newEventData[data.eventName] = {
			currentCooldown = data.currentCooldown,
			eventType = data.eventType,
			button = possibleButton
		}
	end
	
	-- Store the event data as "eventData" table. Then, clear the given event data table.
	eventData = newEventData
	table.clear(givenEventData)
end
	
-- Startup Functions --
local function playTerminalOpenAnimation()
	
	-- Wait for most of the camera work to be completed.
	task.wait(slowFade.Time / 2)

	-- Play the animation.
	tweenService:Create(terminalScreen, guiFadeTween, {
		GroupTransparency = 0
	}):Play()
	
	-- Wait a bit longer than the tween time.
	task.wait(guiFadeTween.Time * 1.1)
	
	-- Show the input line and what is pretyped.
	terminalInput.Visible = true
	task.wait(.5)
	
	-- Load out the terminal.
	tweenService:Create(terminalScreen, guiFadeTween, {
		GroupTransparency = 1
	}):Play()
end

local function toggleActiveView(isActive: boolean)

	-- Get the character if they do not exist.
	if not character then
		character = localPlr.Character
	end

	-- Toggle other player GUI and this GUI.
	toggleGUIBindableEvent:Fire(not isActive)
	gui.Active = isActive
	
	-- Grab the event data from the server if we haven't done so yet.
	if isActive and not grabbedData then
		
		-- The player has now grabbed the data.
		grabbedData = true
		
		-- Request the data from the server
		givenEventData, serverCooldown, remainingServerCooldown = getEventDataFunction:InvokeServer()
		setupEventGUIFromData()
		
		-- Update the server cooldown GUI.
		updateServerCooldownGUI()
	end
	
	-- Force the player to walk upon the camera changing.
	local xButtonTargetTransparency
	if isActive then

		-- Force the player to walk to prevent unexpected behavior.
		forceStateBindableEvent:Fire(movementStateEnum.walking)
		toggleVFXBindableEvent:Fire(false)
		runService.RenderStepped:Wait()

		-- Store the old camera CFrame
		oldCameraCFrame = camera.CFrame

		-- Adjust the camera.
		camera.CameraType = Enum.CameraType.Scriptable

		-- Move the camera to the desired position.
		tweenService:Create(camera, slowFade, {
			CFrame = cameraPart.CFrame
		}):Play()

		-- Show the X button.
		xButtonTargetTransparency = 0
		
		-- Disable the player's controls and the proximity prompt.
		trigger.Enabled = false
		controls:Disable()
		
		-- Play the opening animation.
		playTerminalOpenAnimation()
		
		-- Show the event selection GUI.
		tweenService:Create(eventSelection, guiFadeTween, {
			GroupTransparency = 0
		}):Play()
		
		-- Wait for the GUI to finish loading. Then reset all initial transparencies.
		task.wait(guiFadeTween.Time)
		terminalInput.Visible = false
		eventSelection.Interactable = true
		closeButtonContainer.Interactable = true -- Show the X button later to prevent cheese.
	else

		-- Tween back to the player's camera.
		tweenService:Create(camera, slowFade, {
			CFrame = oldCameraCFrame
		}):Play()
		
		-- Hide the selection GUI.
		eventSelection.Interactable = false
		tweenService:Create(eventSelection, slowFade, {
			GroupTransparency = 1
		}):Play()
		
		-- Wait for the tween to complete, then restore camera control.
		task.wait(slowFade.Time)
		camera.CameraType = Enum.CameraType.Custom
		toggleVFXBindableEvent:Fire(true)

		-- Hide the X button.
		xButtonTargetTransparency = 1
		closeButtonContainer.Interactable = false

		-- Enable the player's controls.
		controls:Enable()
		task.delay(slowFade.Time, function () -- Delayed to prevent weird tween functionality.
			trigger.Enabled = true
		end)
	end

	-- Hide/show the close button.
	tweenService:Create(closeButtonContainer, slowFade, {
		GroupTransparency = xButtonTargetTransparency
	}):Play()
end

-- Event Functions --
local function periodic(deltaTime: number)
	
	-- We cannot update event data if we are unable to do
	if not eventData or not remainingServerCooldown then
		return
	end
	
	-- Increase accumulated time and return if it isn't time to update everything.
	accumulatedTime += deltaTime
	if accumulatedTime < updateTime then
		return
	end
	
	-- Go through all of the gui and update the information if possible.
	for _, data in pairs(eventData) do
		
		-- Decrease the cooldown on the event (if possible)
		local shouldUpdateGUI = true
		if data.currentCooldown - accumulatedTime < 0 then
			
			-- If the cooldown was already 0, don't update the GUI.
			if data.currentCooldown == 0 then
				shouldUpdateGUI = false
			end
			
			data.currentCooldown = 0
		else
			data.currentCooldown -= accumulatedTime
		end
		
		-- Update the GUI if told to do so.
		if shouldUpdateGUI then
			updateGUIInformation(data.button, data.currentCooldown)
		end
	end
	
	-- Update the server cooldown GUI.
	local shouldUpdateServerCooldownGUI = true
	if remainingServerCooldown - accumulatedTime < 0 then
		
		-- If the server cooldown is already zero, no need to reupdate the GUI.
		if remainingServerCooldown == 0 then
			shouldUpdateServerCooldownGUI = false
		end
		
		remainingServerCooldown = 0
	else
		remainingServerCooldown -= accumulatedTime
	end
	
	-- If told to do so, update the server cooldown gui.
	if shouldUpdateServerCooldownGUI then
		updateServerCooldownGUI()
	end
	
	-- Reset the accumulated time.
	accumulatedTime = 0
end

local function eventDataUpdated(data)
	
	-- Return if data hasn't been grabbed yet.
	if not eventData then
		return
	end
	
	-- Grab the relevant event information.
	local storedData = eventData[data.eventName]
	if not storedData then
		return
	end

	-- Reset the server cooldown GUI.
	remainingServerCooldown = serverCooldown
	updateServerCooldownGUI()
	
	-- Update the cooldown time and the GUI.
	storedData.currentCooldown = data.currentCooldown
	updateGUIInformation(storedData.button, storedData.currentCooldown)
end

local function playerDied()
	if gui.Active then
		toggleActiveView(false)
	end
end

-- Events --
runService.RenderStepped:Connect(periodic)
eventDataUpdatedEvent.OnClientEvent:Connect(eventDataUpdated)
deathEvent.OnClientEvent:Connect(playerDied)

-- GUI Visibility Events --
trigger.Triggered:Connect(function ()
	toggleActiveView(true)
end)

closeButton.Activated:Connect(function ()
	toggleActiveView(false)
end)