-- Services --
local serverStorage = game:GetService("ServerStorage")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- Bindable Events --
local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local spawnRandomEvent = bindableEvents:WaitForChild("SpawnRandomEvent")

local stateOfTheWorld = serverStorage:WaitForChild("State of the world")
local bloodlustActive = stateOfTheWorld:WaitForChild("bloodlust_active")

-- Objects --
local ambientLights = workspace:WaitForChild("Ambient Lights"):GetChildren()

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local normalLightSettingsFolder = ambientLightSettings:WaitForChild("Normal")
local bloodlustSettingsFolder = ambientLightSettings:WaitForChild("Bloodlust")
local normalSettings = {
	[1] = { -- Sunrise
		brightness = normalLightSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("brightness"),
		lighting_color = normalLightSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("lighting_color"),
		neon_part_color = normalLightSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("neon_part_color")
	},
	[2] = { -- Midday
		brightness = normalLightSettingsFolder:FindFirstChild("Midday"):GetAttribute("brightness"),
		lighting_color = normalLightSettingsFolder:FindFirstChild("Midday"):GetAttribute("lighting_color"),
		neon_part_color = normalLightSettingsFolder:FindFirstChild("Midday"):GetAttribute("neon_part_color")
	},
	[3] = { -- Sunset
		brightness = normalLightSettingsFolder:FindFirstChild("Sunset"):GetAttribute("brightness"),
		lighting_color = normalLightSettingsFolder:FindFirstChild("Sunset"):GetAttribute("lighting_color"),
		neon_part_color = normalLightSettingsFolder:FindFirstChild("Sunset"):GetAttribute("neon_part_color")
	},
	[4] = { -- Night
		brightness = normalLightSettingsFolder:FindFirstChild("Night"):GetAttribute("brightness"),
		lighting_color = normalLightSettingsFolder:FindFirstChild("Night"):GetAttribute("lighting_color"),
		neon_part_color = normalLightSettingsFolder:FindFirstChild("Night"):GetAttribute("neon_part_color")
	}
}
local bloodlustSettings = {
	[1] = { -- Sunrise
		brightness = bloodlustSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("brightness"),
		lighting_color = bloodlustSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("lighting_color"),
		neon_part_color = bloodlustSettingsFolder:FindFirstChild("Sunrise"):GetAttribute("neon_part_color")
	},
	[2] = { -- Midday
		brightness = bloodlustSettingsFolder:FindFirstChild("Midday"):GetAttribute("brightness"),
		lighting_color = bloodlustSettingsFolder:FindFirstChild("Midday"):GetAttribute("lighting_color"),
		neon_part_color = bloodlustSettingsFolder:FindFirstChild("Midday"):GetAttribute("neon_part_color")
	},
	[3] = { -- Sunset
		brightness = bloodlustSettingsFolder:FindFirstChild("Sunset"):GetAttribute("brightness"),
		lighting_color = bloodlustSettingsFolder:FindFirstChild("Sunset"):GetAttribute("lighting_color"),
		neon_part_color = bloodlustSettingsFolder:FindFirstChild("Sunset"):GetAttribute("neon_part_color")
	},
	[4] = { -- Night
		brightness = bloodlustSettingsFolder:FindFirstChild("Night"):GetAttribute("brightness"),
		lighting_color = bloodlustSettingsFolder:FindFirstChild("Night"):GetAttribute("lighting_color"),
		neon_part_color = bloodlustSettingsFolder:FindFirstChild("Night"):GetAttribute("neon_part_color")
	}
}
local targetTime = 1
local timeSettings = ambientLightSettings:WaitForChild("Time Settings")
local dayNightTime = timeSettings:GetAttribute("day_night_time_in_seconds")
local transitionTime = timeSettings:GetAttribute("transition_time_in_seconds")

-- Misc --
local playingTweens = {}
local currentTime = 0
local tweenTime = transitionTime / 2
local nextTransitionTime = transitionTime / 2 -- Time until lighting changes

-- Functions --
--[[
 -
 -
 -
--]]
local function tweenLight(object, tweenInfo, surfaceLightProperties, pointLightProperties, neonPartProperties) 
	
	-- Make sure that the object has a emitter. If it doesn't, then tell the user and skip over to the next object. 
	local emitter = object:FindFirstChild("Emitter")
	if emitter == nil then
		warn("Error: " .. object.Name .. " does not contain an emitter. Cannot tween lighting properly.")
		return
	end
	
	-- Get the surface light from the emitter and tween it's properties
	local surfaceLight = emitter:FindFirstChild("SurfaceLight")
	if surfaceLight then
		local surfaceLightTween = tweenService:Create(surfaceLight, tweenInfo, surfaceLightProperties)
		table.insert(playingTweens, surfaceLightTween)
		surfaceLightTween:Play()
	end
	
	-- Get the neon part from the emitter and create a tween to change it's properties.
	local neonPart = object:FindFirstChild("NeonPart")
	if neonPart then
		local neonPartTween = tweenService:Create(neonPart, tweenInfo, neonPartProperties)
		table.insert(playingTweens, neonPartTween)
		neonPartTween:Play()
	end
	
	-- Get the point light (If it exists) from the emitter and create a tween to change it's properties.
	local lightPoint = emitter:FindFirstChild("LightPoint")
	if lightPoint ~= nil then
		
		-- Get the pointlight inside of the light point
		local pointLight = lightPoint:WaitForChild("PointLight")
		
		-- Create a tween and then play it.
		local pointLightTween = tweenService:Create(pointLight, tweenInfo, pointLightProperties)
		table.insert(playingTweens, pointLightTween)
		pointLightTween:Play()
	end
end

--[[
 - Stops all tweens from playing and remove them from the playingTweens array.
--]]
local function stopAll()
	
	-- Loop through all currently playing tweens and stop them from playing and remove them from the 
	-- playingtweens table.
	for _,tween in ipairs(playingTweens)  do
		tween:Pause() -- We use pause instead of cancel, since cancel resets the tween back to it's original state.
	end
	
	-- Remove all of the paused tweens from the array.
	table.clear(playingTweens)
end

--[[
 -
 -
 -
--]]
local function updateLightingTweens()
	
	-- Get the values for the tween
	local targetLightingSettings
	if not bloodlustActive.Value then
		targetLightingSettings = normalSettings[targetTime]
	else
		targetLightingSettings = bloodlustSettings[targetTime]
	end
	
	-- Create the properties for each kind of object
	local surfaceLightProperties = {
		Color = targetLightingSettings.lighting_color,
		Brightness = targetLightingSettings.brightness
	}
	local pointLightProperties = {
		Color = targetLightingSettings.lighting_color,
		Brightness = targetLightingSettings.brightness / 8
	}
	
	-- If we are transitioning to night, then make the pointlights brightness be determined by a different ratio.
	if targetTime == 4 then
		pointLightProperties.Brightness = targetLightingSettings.brightness / 2
	end
	local neonPartProperties = {
		Color = targetLightingSettings.neon_part_color
	}
	
	-- Create tween info 
	local m_tweenTime = tweenTime - currentTime
	local tweenInfo = TweenInfo.new(m_tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	
	-- Tween all of the lights --
	for _,object in ipairs(ambientLights) do
		tweenLight(object, tweenInfo, surfaceLightProperties, pointLightProperties, neonPartProperties)
		task.wait()
	end
end

--[[
 - 
 - 
 - 
--]]
local function changeLightingType(bloodlust) 
	
	-- Stop of the tweens that are currently playing.
	stopAll()
	
	-- Transition into the next lighting state
	updateLightingTweens()
end

--[[
 -
 -
 -
--]]
local function getNextTimeTarget()
	
	-- Att 1 to our current target.
	targetTime = targetTime + 1
	
	-- If our target is greater than 4, then set it back to 1.
	if targetTime > 4 then
		targetTime = 1
	end
	
	-- Return the new target time.
	return targetTime
end

--[[
 - Adds the change in time to the current time and (if above the transition time) transitions towards the next daylight stage.
 -
 - @param deltaTime The change in time
--]]
local function updateTime(deltaTime)
	
	--Add the change in time to our total time so that we are able to make decisions based on time.
	currentTime += deltaTime
	
	-- If enough time has passed then transition towards the next lighting state.
	if currentTime > nextTransitionTime then
		
		-- Clear out the table of currently playing tweens, since they should be done playing.
		table.clear(playingTweens)
		
		-- Update the time target
		targetTime = getNextTimeTarget()
		
		-- Update transition settings
		tweenTime = transitionTime / 2
		
		-- Set the duration of the time state to be half of the transition time (The same amount of time as the tween). Then,
		-- if the time we are transitioning to is associated with an even number (is night/day) than have it last as long as
		nextTransitionTime = transitionTime / 2
		if targetTime / 2 == math.round(targetTime / 2) then
			
			-- Ensure day and night last longer than sunrise and sunset.
			nextTransitionTime = dayNightTime
			
			-- Spawn a random event if bloodlust is not currently active.
			if not bloodlustActive.Value then
				spawnRandomEvent:Fire(targetTime == 4)
			end
		end
		
		-- Set time back to 0
		currentTime = 0
		
		-- Transition into the next lighting stage 
		updateLightingTweens()
	end
end

-- Events --
runService.Heartbeat:Connect(updateTime)
bloodlustActive.Changed:Connect(changeLightingType)

-- Setup --
local function setup()
	
	-- Get the settings for the currently set time
	local targetLightingSettings = normalSettings[targetTime]

	-- Create the properties for each kind of object
	local surfaceLightProperties = {
		Color = targetLightingSettings.lighting_color,
		Brightness = targetLightingSettings.brightness
	}
	local pointLightProperties = {
		Color = targetLightingSettings.lighting_color,
		Brightness = targetLightingSettings.brightness / 8
	}

	-- If we are transitioning to night, then make the pointlights brightness be determined by a different ratio.
	if targetTime == 4 then
		pointLightProperties.Brightness = targetLightingSettings.brightness / 2
	end
	local neonPartProperties = {
		Color = targetLightingSettings.neon_part_color
	}

	-- Create tween info 
	local tweenInfo = TweenInfo.new(0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	-- Tween all of the lights --
	for _,object in ipairs(ambientLights) do
		tweenLight(object, tweenInfo, surfaceLightProperties, pointLightProperties, neonPartProperties)
	end
end

-- Start the lighting.
setup()