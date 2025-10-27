-- Services --
local serverStorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")
local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

-- Bindable Events --
local randomEvents = serverStorage:WaitForChild("Random Events")
local nightEvents = randomEvents:WaitForChild("Night")
local POWER_OUTAGE_EVENT = nightEvents:WaitForChild("POWER_OUTAGE_EVENT")

-- Objects --
local stateOfTheWorld = serverStorage:WaitForChild("State of the world")
local isPowerOut = stateOfTheWorld:WaitForChild("power_outage")

local ceilingLights = workspace:WaitForChild("Ceiling Lights")
local powerAffectedLight = ceilingLights:WaitForChild("Power Outage Affected Lights")
local powerAffectedLightFolders = powerAffectedLight:GetChildren()

local sparksEffect = script:WaitForChild("Sparks")

local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local timeSettings = ambientLightSettings:WaitForChild("Time Settings")

-- Settings --
local defaultemitterColor = Color3.fromRGB(255, 156, 131)
local defaultSurfaceLightBrightness = 0.2
local defaultPointLightBrightness = 0.05

local baseDuration = timeSettings:GetAttribute("day_night_time_in_seconds") + timeSettings:GetAttribute("transition_time_in_seconds")
local useSparks = true

-- Functions --
local function toggleLight(light: Model, shouldBeOn: boolean)
	
	-- Get the settings to tween the light's properties to.
	local emitterColor = Color3.fromRGB(0, 0, 0)
	local pointLightBrightness = 0
	local surfaceLightBrightness = 0
	if shouldBeOn then
		emitterColor = light:GetAttribute("emitterColor") or defaultemitterColor
		pointLightBrightness = light:GetAttribute("PointLightBrightness") or defaultPointLightBrightness
		surfaceLightBrightness = light:GetAttribute("SurfaceLightBrightness") or defaultSurfaceLightBrightness
	end
	
	-- Ensure that the light has a model.
	if not light:IsA("Model") then
		return
	end
	
	-- Verify that the light has a light emitter.
	local emitter = light:FindFirstChild("emitter")
	if not emitter then
		return
	end
	
	-- Tween the emitter's color. Black = off, other color = on.
	tweenService:Create(emitter, defaultTween, {Color=emitterColor}):Play()
	
	-- Toggle the light's beam if present.
	local lightBeam = emitter:FindFirstChild("Light Beam")
	if lightBeam then
		lightBeam.Enabled = shouldBeOn
	end
	
	-- Toggle the surface light if present.
	local surfaceLight = emitter:FindFirstChild("SurfaceLight")
	if surfaceLight then
		tweenService:Create(surfaceLight, defaultTween, {Brightness = surfaceLightBrightness}):Play()
	end

	-- Check if there is a Light Point attachment present.
	local lightPoint = emitter:FindFirstChild("LightPoint")
	if not lightPoint then
		return
	end

	-- Toggle the point light, if present.
	local pointLight = lightPoint:FindFirstChild("PointLight")
	if pointLight then
		tweenService:Create(pointLight, defaultTween, {Brightness = pointLightBrightness}):Play()
	end
	
	-- Check if there is a Light Point2 attachment present. This light is only present in station lights.
	local lightPoint2 = emitter:FindFirstChild("LightPoint2")
	if lightPoint2 then
		
		-- Toggle the point light, if present.
		local pointLight2 = lightPoint2:FindFirstChild("PointLight")
		if pointLight2 then
			tweenService:Create(pointLight2, defaultTween, {Brightness = pointLightBrightness / 2}):Play()
		end
	end
	
	-- Shoot out sparks. (If enabled)
	if useSparks then
		
		local sparksClone = sparksEffect:Clone()
		sparksClone.Parent = emitter
		sparksClone:Emit(200)
		debris:AddItem(sparksClone, 2)
	end
end

local function toggleLights(shouldBeOn: boolean)
	for _, lightFolder in ipairs(powerAffectedLightFolders) do
		
		-- Iterate through all of the lights in the folder and adjust their state.
		for _, light in ipairs(lightFolder:GetChildren()) do
			toggleLight(light, shouldBeOn)
		end
	end 
end

local function powerOutage(duration: number?)
	
	-- Toggle the power outage state of the world.
	isPowerOut.Value = true

	-- Wait for the event to expire.
	task.wait(duration or baseDuration)
	
	-- Enable all of the industrial lights.
	isPowerOut.Value = false
end

-- Events --
POWER_OUTAGE_EVENT.Event:Connect(powerOutage)

-- This is its own separate function to allow external influences to impact lighting.
isPowerOut.Changed:Connect(function ()
	if isPowerOut.Value then
		
		-- Disable all of the industrial lights.
		toggleLights(false)
		return
	end
	
	-- Re-enable the lights.
	-- Disable all of the industrial lights.
	toggleLights(true)
end)

