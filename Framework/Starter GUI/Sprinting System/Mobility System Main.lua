-- Services --
local runService = game:GetService("RunService")
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local players = game:GetService("Players")
local player = players.LocalPlayer

local tweenService = game:GetService("TweenService")
local cameraTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local guiFadeTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Bindable Events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local guiBindableEvents = bindableEvents:WaitForChild("GUI")
local toggleGUIBindableEvent = guiBindableEvents:WaitForChild("ToggleGUI")

local movementBindableEvents = bindableEvents:WaitForChild("Movement")
local forceStateBindableEvent = movementBindableEvents:WaitForChild("ForceMovementStateEvent")

-- Remote Events --
local framework = replicatedStorage:WaitForChild("Framework")
local remoteEvents = framework:WaitForChild("Remote Events")
local guiRemoteEvents = remoteEvents:WaitForChild("GUI")
local toggleGUIEvent = guiRemoteEvents:WaitForChild("ToggleGUI")

local movementEvents = remoteEvents:WaitForChild("MovementEvents")
local forceStateEvent = movementEvents:WaitForChild("ForceMovementStateEvent")

local playerEvents = remoteEvents:WaitForChild("Player")
local characterSetupEvent = playerEvents:WaitForChild("CharacterSetup")

-- Modules --
local modules = framework:WaitForChild("Modules")
local configs = modules:WaitForChild("Configs")
local movementMode = require(configs:WaitForChild("MovementMode"))

local enums = modules:WaitForChild("Enums")
local movementStateEnum = require(enums:WaitForChild("MovementState"))

-- Objects --
local character = player.Character
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator") -- Used for Animations

local camera: Camera = game.Workspace:WaitForChild("Camera")

local gui = script.Parent
local container = gui:WaitForChild("CanvasGroup")
local overlay = container:WaitForChild("Overlay")
local staminaText = container:WaitForChild("StaminaText")

-- Settings --
local maxStamina = 200
local stamina = maxStamina
local maxWidth = .99

local speedMultiplier = 1  -- Default overridden by player setup script.
local costMultiplier = 1 -- Default overridden by player setup script.
local gainMultiplier = 1  -- Default overridden by player setup script.

local shiftEventName = "shiftPressed"
local controlEventName = "controlPressed"

-- Flags --
local isTransitionActive = false
local guiEnabled = true

-- Storage --
local movementStates: movementMode.MovementModePreset
local currentState: movementMode.StateSettings
local sprintingStats: Configuration

-- Utility Functions --
--[[
Roblox's table.clone() won't clone the full module. This leads to animations being loaded to the animator and 
stored in the original modules, leading to errors when we attempt to reload them after the player respawns.

Thus, we need to "Deep Copy" the table to prevent this from happening, thus fixing the issue.
]]
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value) -- Recursively copy nested tables
		else
			copy[key] = value
		end
	end
	return copy
end

local function updateSettings()
	
	-- Reset walkspeed to unmultiplied state.
	humanoid.WalkSpeed /= speedMultiplier
	
	-- Update values.
	speedMultiplier = sprintingStats:GetAttribute("SpeedMultiplier")
	costMultiplier = sprintingStats:GetAttribute("StaminaCostMultiplier")
	gainMultiplier = sprintingStats:GetAttribute("StaminaGainMultiplier")
	maxStamina = sprintingStats:GetAttribute("MaxStamina")
	
	-- Reapply multiplier with new values.
	humanoid.WalkSpeed *= speedMultiplier
end

local function setupSprintingStats()

	-- Grab the sprinting stats object (if it exists)
	sprintingStats = character:FindFirstChild("Sprinting Stats")

	-- Setup the sprinting stats.
	if sprintingStats then

		-- Update settings to work with the new stats.
		updateSettings()

		-- Connect to the events.
		sprintingStats.AttributeChanged:Connect(updateSettings)
	end
end

local function updateGUI()
	overlay.Size = UDim2.new(maxWidth * (stamina / maxStamina), 0, .9, 0)
	staminaText.Text = math.round(stamina) .. "/" .. maxStamina
end

local function updateAnimations(moveMagnitude: number)
	
	-- Play Walking Animation --
	if moveMagnitude > 0 and not isTransitionActive then
		if not currentState.animations.walkinAnim.IsPlaying then
			currentState.animations.walkinAnim:Play()
		end
	else
		currentState.animations.walkinAnim:Stop()
	end
end

local function updateStamina(deltaTime: number, moveMagnitude: number)
	
	-- Calculate the stamina change.
	local staminaChange
	
	-- If the player isn't moving, then the player will regen stamina.
	if moveMagnitude > 10e-7 then
		staminaChange = currentState.staminaCostPerSecond
	else
		staminaChange = currentState.idleRegen
	end
	
	-- Make the change time dependent.
	staminaChange*= deltaTime
	
	-- Multiply the stamina change by the multiplier if the player is sprinting OR if the multiplier applies to non-stamina loss changes.
	if math.sign(staminaChange) > 0 then
		staminaChange *= costMultiplier
	else
		staminaChange *= gainMultiplier
	end
	
	-- Update the stamina.
	if stamina - staminaChange > maxStamina then
		stamina = maxStamina
	elseif stamina - staminaChange < 0 then
		stamina = 0
	else
		stamina -= staminaChange
	end
end

-- State Change Functions --
local function stopAnimations()
	currentState.animations.walkinAnim:Stop()
	currentState.animations.idleAnim:Stop()
end

local function changeState(state: movementMode.StateSettings)
	
	-- Stop all animations. (Only if there are animations to be stopped)
	if currentState then
		stopAnimations()
	end
	
	-- Change the current state in settings.
	currentState = state
	
	-- Update player stats.
	humanoid.WalkSpeed = currentState.stats.walkSpeed * speedMultiplier
	humanoid.UseJumpPower = true
	humanoid.JumpPower = currentState.stats.jumpPower
	
	-- Play the current idle animation for the current state.
	currentState.animations.idleAnim:Play()
	
	-- Make sure the Camera isn't Already in Position 
	if camera.FieldOfView ~= currentState.cameraSettings.fov then

		-- Tween Camera into Position --
		tweenService:Create(camera, cameraTween, {FieldOfView = currentState.cameraSettings.fov}):Play()
		tweenService:Create(humanoid, cameraTween, {CameraOffset = currentState.cameraSettings.offset}):Play()
	end
	
	-- The transition animation is no longer active.
	isTransitionActive = false
end

local function eventForceState(state: movementStateEnum.movementState)

	-- Since the table is cloned, we need to convert the broader table to the specific state.
	if state == movementStateEnum.walking then
		changeState(movementStates.walking)
	elseif state == movementStateEnum.crouching then
		changeState(movementStates.crouching)
	elseif state == movementStateEnum.running then
		changeState(movementStates.running)
	end
end

local function handleShiftPress()
	
	-- Change the state differently based on which state the player is currently in.
	if currentState == movementStates.crouching then
		
		-- Toggle the transition active.
		isTransitionActive = true
		
		-- Play the transition animations and wait the required amount of time.
		if currentState.animations.transitionOutAnim then
			currentState.animations.transitionOutAnim:Play()
			task.wait(currentState.animations.transitionOutAnim.Length)
		end
		
		-- Change the state to walking.
		changeState(movementStates.walking)
	elseif currentState == movementStates.walking then
		
		-- Change the state to sprinting.
		changeState(movementStates.running)
	else
		
		-- Change the state to walking, as the player is already sprinting of panicked..
		changeState(movementStates.walking)
	end
end

local function handleControlPressed()

	-- Change the state differently based on which state the player is currently in.
	if currentState == movementStates.crouching then

		-- Toggle the transition active.
		isTransitionActive = true

		-- Play the transition animations and wait the required amount of time.
		if currentState.animations.transitionOutAnim then
			currentState.animations.transitionOutAnim:Play()
			task.wait(currentState.animations.transitionOutAnim.Length)
		end

		-- Change the state to walking.
		changeState(movementStates.walking)
	else

		-- Toggle the transition active.
		isTransitionActive = true

		-- Play the transition animations and wait the required amount of time.
		if movementStates.crouching.animations.transitionOutAnim then
			movementStates.crouching.animations.transitionOutAnim:Play()
			task.wait(movementStates.crouching.animations.transitionOutAnim.Length)
		end

		-- Change the state to walking.
		changeState(movementStates.crouching)
	end
end

local function inputBegan(eventName, inputState, _inputObject)
	
	-- Return if the input state has not begun.
	if not (inputState == Enum.UserInputState.Begin) then
		return
	end
	
	-- Ignore inputs if the GUI is dissabled.
	if not guiEnabled then
		return
	end
	
	-- Switch the state differently based on the key pressed.
	if eventName == shiftEventName then
		handleShiftPress()
	elseif eventName == controlEventName then
		handleControlPressed()
	end
end

-- Event Functions --
local function periodic(deltaTime)
	
	-- Prevent the script from running befroe setup has completed.
	if not currentState then
		return
	end
	
	-- Attempt to setup sprinting stats if they weren't found.
	if not sprintingStats then
		setupSprintingStats()
	end
	
	local moveMagnitude = humanoid.MoveDirection.Magnitude
	updateStamina(deltaTime, moveMagnitude)
	
	-- Return the player to regular walking if their stamina is less than or equal to zero.
	if stamina <= 0 then
		changeState(movementStates.walking)
	end
	
	-- Update animations.
	updateAnimations(moveMagnitude)
	
	-- Update the GUI.
	updateGUI()
end

local function toggleGUI(toActive: boolean)
	
	local targetTransparency
	if toActive then
		targetTransparency = 0 -- Visible GUI.
		guiEnabled = true -- The GUI is enabled.
	else
		targetTransparency = 1 -- Invisible GUI.
		guiEnabled = false -- The GUI is disabled.
	end
	
	-- Fade the GUI in/out.
	tweenService:Create(container, guiFadeTween, {
		GroupTransparency = targetTransparency
	}):Play()
end

-- Setup Functions --
local function setup()
	
	-- Grab the default animations.
	movementStates = deepCopy(movementMode.default) -- Clone the table to prevent accidental value changes.
	
	-- Reset the camera's FOV.
	camera.FieldOfView = movementStates.walking.cameraSettings.fov
	
	-- Load the animations.
	for movementState, data in movementStates do
		for animType, animation in data.animations do
			data.animations[animType] = animator:LoadAnimation(animation)
		end
	end
	
	-- Set the current movement mode.
	changeState(movementStates.walking)
	
	-- Sttampt to setup sprinting stats.
	setupSprintingStats()
end

-- Events --
runService.Heartbeat:Connect(periodic)
contextActionService:BindAction(shiftEventName, inputBegan, true, Enum.KeyCode.LeftShift)
contextActionService:BindAction(controlEventName, inputBegan, true, Enum.KeyCode.LeftControl)

toggleGUIEvent.OnClientEvent:Connect(toggleGUI)
toggleGUIBindableEvent.Event:Connect(toggleGUI)

forceStateEvent.OnClientEvent:Connect(eventForceState)
forceStateBindableEvent.Event:Connect(eventForceState)

-- Mobile Setup --
contextActionService:SetTitle(shiftEventName, "Sprint")
contextActionService:SetPosition(shiftEventName, UDim2.new(.5, 0, 0.2, 0))

contextActionService:SetTitle(controlEventName, "Crouch")
contextActionService:SetPosition(controlEventName, UDim2.new(0.3, 0, 0.4, 0))

-- Setup --
setup()