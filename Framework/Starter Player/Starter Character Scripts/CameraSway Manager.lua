-- Sorry to whoever is trying to read this! I was pressed for time when making this, so comments aren't the best. Lmk if you need help working with this. - Lolbit757575
-- Services --
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- Bindable events --
local framework = replicatedStorage:WaitForChild("Framework")
local bindableEvents = framework:WaitForChild("Bindable Events")
local vfxBindableEvents = bindableEvents:WaitForChild("VFX")
local toggleVFXBindableEvent = vfxBindableEvents:WaitForChild("ToggleVFX")

-- Modules --
local modules = framework:WaitForChild("Modules")
local enums = modules:WaitForChild("Enums")
local cameraMovementState = require(enums:WaitForChild("CameraMovementState"))

-- Objects --
local camera = workspace.CurrentCamera
local cameraOffset = script:WaitForChild("Camera Offset") -- This is a scriptable camera instance that will be used to render the camera.

-- Settings --
local walkspeedIntensityMultiplier = .025 -- Every 20 walkspeed increases intensity by 1
local walkspeedFrequencyMultiplier = .4 -- Every 2.5 walkspeed increases frequency by 1
local baseIntensity = math.rad(0.25)
local baseFrequency = .1
local swayDecay = .9

local walkspeedPositionIntensityMultiplier = .05 -- Every 20 walkspeed increases intensity by 1
local basePositionIntensity = 0

local rotationalMagnitudeThreshold = .01
local movingMagnitudeThreshold = .25 -- Required magnitude to be considered walking.

local rotationalSwaySwapThreshold = math.rad(.5)
local rotationalDecay = 0.98
local swapRotationalDecay = .85

local rotationalGrowthMultiplier = 1.1
local maxRotationalSway = math.rad(1)

local walkspeedRotationalIntensityMultiplier = 0.05
local walkspeedRotationalGrowthMultiplier = 0.005
local timeSinceRotation = 0
local decayTimeThreshold = 0.2

-- Flags --
local setup = false
local active = true

-- Storage --
local character, humanoid: Humanoid
local lastDirection 
local sway = 0
local positionSway = 0
local rotationalSway = 0

--- Functions ---
-- Utility --

-- Setup --
local function setupVariables(): boolean

	-- Attempt to get the player's character.
	character = localPlayer.Character
	if not character then
		return false
	end

	-- Attempt to get the player's humanoid.
	humanoid = character:FindFirstChildOfClass("Humanoid")

	-- Return whether or not both the humanoid and character were found.
	return (humanoid ~= nil) 
end


local function calculateRotationalMovement(deltaTime: number) : number

	local lookVecotr = camera.CFrame.LookVector
	local lookVector2d = Vector2.new(lookVecotr.X, lookVecotr.Z).Unit

	if not lastDirection then
		lastDirection = lookVector2d
	end

	local angle = math.asin(lastDirection:Cross(lookVector2d)) -- + for clockwise, - for counter-clockwise

	-- Store the last direction.
	lastDirection = lookVector2d

	return angle
end

local function calculateCameraMovementState(deltaTime): {number}

	-- Store all of the ways the player is moving.
	local activeStates = {}

	-- Determine if the player is rotating or not.
	local cameraRotationalVelocityRadians = calculateRotationalMovement(deltaTime)
	if math.abs(cameraRotationalVelocityRadians) > rotationalMagnitudeThreshold then
		table.insert(activeStates, cameraMovementState.rotating)
	end

	-- Determine if the player is moving or not.
	local movementMagnitude = humanoid.MoveDirection.Magnitude
	if movementMagnitude > movingMagnitudeThreshold then
		table.insert(activeStates, cameraMovementState.moving)
	end

	-- Return all of the ways the player is moving.
	return activeStates, cameraRotationalVelocityRadians
end


local function renderStepped(deltaTime: number)

	-- Return if the effect is inactive.
	if not active then
		return
	end

	-- If the player's humanoid and character are not present then
	if not setup then
		setup = setupVariables()

		-- Return if setup failed.
		if not setup then 
			return	
		end
	end

	-- Get all of the ways the player is moving.
	local activeStates, rotationalVelocity = calculateCameraMovementState(deltaTime)

	-- If the player is rotating.
	if table.find(activeStates, cameraMovementState.rotating) then

		-- Reset the time since the player last rotated.
		timeSinceRotation = 0

		if rotationalSway == 0 then
			rotationalSway = 0.1
		end

		if math.sign(rotationalVelocity) ~= math.sign(rotationalSway) then

			if math.abs(rotationalSway) <= rotationalSwaySwapThreshold then
				rotationalSway *= -1
			else
				rotationalSway *= math.pow(swapRotationalDecay, 240*deltaTime)
			end
		else
			rotationalSway *= math.pow(rotationalGrowthMultiplier + (walkspeedRotationalGrowthMultiplier * humanoid.WalkSpeed), 240*deltaTime)

			if math.abs(rotationalSway) > maxRotationalSway + math.rad(walkspeedRotationalIntensityMultiplier * humanoid.WalkSpeed) then
				rotationalSway = math.sign(rotationalSway) * (maxRotationalSway + math.rad(walkspeedRotationalIntensityMultiplier * humanoid.WalkSpeed))
			end
		end
	else

		timeSinceRotation += deltaTime

		if timeSinceRotation > decayTimeThreshold then
			rotationalSway *= math.pow(rotationalDecay, 240*deltaTime)
		end
	end

	if table.find(activeStates, cameraMovementState.moving) then
		local time = tick() * (baseFrequency + (humanoid.WalkSpeed * walkspeedFrequencyMultiplier))
		sway = math.sin(time) * (baseIntensity + math.rad(humanoid.WalkSpeed * walkspeedIntensityMultiplier))
		positionSway =  math.sin(2 * time) * (basePositionIntensity + math.rad(humanoid.WalkSpeed * walkspeedPositionIntensityMultiplier))
	else
		sway *= math.pow(swayDecay, 240*deltaTime)
		positionSway *= math.pow(swayDecay, 240*deltaTime)
	end

	camera.CFrame = camera.CFrame * CFrame.new(0, positionSway * 10, 0) * CFrame.Angles(cameraOffset.Value:ToEulerAnglesXYZ()) * CFrame.Angles(0, 0, sway - rotationalSway)
end

local function toggleActive(isActive)
	active = isActive
end

-- Events- -
runService.RenderStepped:Connect(renderStepped)
toggleVFXBindableEvent.Event:Connect(toggleActive)