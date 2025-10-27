-- Services --
local serverStorage = game:GetService("ServerStorage")
local lighting = game:GetService("Lighting")
local soundService = game:GetService("SoundService")

local tweenService = game:GetService("TweenService")
local defaultTween = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Bindable  Events --
local bindableEvents = serverStorage:WaitForChild("Bindable Events")
local deadlySunlightPulseEvent = bindableEvents:WaitForChild("DeadlySunlightPulseEvent")

local randomEvents = serverStorage:FindFirstChild("Random Events")
local dayEvents = randomEvents:FindFirstChild("Day")
local RAIN_EVENT = dayEvents:WaitForChild("RAIN_EVENT")
local FOG_EVENT = dayEvents:WaitForChild("FOG_EVENT")
local DEADLY_SUNLIGHT_EVENT = dayEvents:WaitForChild("DEADLY_SUNLIGHT_EVENT")
local BLOODLUST_EVENT = dayEvents:WaitForChild("BLOODLUST_EVENT")

local nightEvents = randomEvents:FindFirstChild("Night")

local NEW_MOON_EVENT = nightEvents:WaitForChild("NEW_MOON_EVENT")
local FULL_MOON_EVENT = nightEvents:WaitForChild("FULL_MOON_EVENT")

-- Lighting Objects --
local colorCorrection = lighting:WaitForChild("ColorCorrection")
local atmosphere = lighting:WaitForChild("Atmosphere")
local depthOfField = lighting:WaitForChild("DepthOfField")
local blur = lighting:WaitForChild("Blur")

-- Lighting Settings --
local randomEventsLighting = lighting:WaitForChild("RandomEvents")

local rainEvents = randomEventsLighting:WaitForChild("RainEffects")
local rainColorCorrection = rainEvents:WaitForChild("ColorCorrection")
local rainAtmosphere = rainEvents:WaitForChild("Atmosphere")

local fogEffects = randomEventsLighting:WaitForChild("FogEffects")
local fogColorCorrection = fogEffects:WaitForChild("ColorCorrection")
local fogAtmosphere = fogEffects:WaitForChild("Atmosphere")
local fogDepthOfField = fogEffects:WaitForChild("DepthOfField")

local fogEffects = randomEventsLighting:WaitForChild("FogEffects")
local fogColorCorrection = fogEffects:WaitForChild("ColorCorrection")
local fogAtmosphere = fogEffects:WaitForChild("Atmosphere")
local fogDepthOfField = fogEffects:WaitForChild("DepthOfField")

local harshSunlightEffects = randomEventsLighting:WaitForChild("HarshSunlight")
local harshSunlightColorCorrection = harshSunlightEffects:WaitForChild("ColorCorrection")
local harshSunlightAtmosphere = harshSunlightEffects:WaitForChild("Atmosphere")
local harshSunlightBlur = harshSunlightEffects:WaitForChild("Blur")

local newMoonEffects = randomEventsLighting:WaitForChild("NewMoon")
local newMoonContrast = newMoonEffects:WaitForChild("ColorCorrection")
local newMoonAtmosphere = newMoonEffects:WaitForChild("Atmosphere")

local fullMoonEffects = randomEventsLighting:WaitForChild("FullMoon")
local fullMoonContrast = fullMoonEffects:WaitForChild("ColorCorrection")
local fullMoonAtmosphere = fullMoonEffects:WaitForChild("Atmosphere")

local bloodlustEffects = randomEventsLighting:WaitForChild("Bloodlust")
local bloodlustCorrection = bloodlustEffects:WaitForChild("ColorCorrection")
local bloodlustAtmosphere = bloodlustEffects:WaitForChild("Atmosphere")

local defaultEffects = randomEventsLighting:WaitForChild("Default")

local defaultColorCorrection = defaultEffects:WaitForChild("ColorCorrection")
local defaultAtmosphere = defaultEffects:WaitForChild("Atmosphere")

-- Sounds --
local rainSoundEffect = soundService:WaitForChild("Heavy Rain SFX")

-- Settings --
local ambientLightSettings = serverStorage:WaitForChild("Ambient light settings")
local settings = ambientLightSettings:WaitForChild("Time Settings")

local transitionTime = settings:GetAttribute("transition_time_in_seconds")
local dayNightTime = settings:GetAttribute("day_night_time_in_seconds")

local stateOfTheWorld = serverStorage:WaitForChild("State of the world")
local bloodlustActive = stateOfTheWorld:WaitForChild("bloodlust_active")

local baseDuration = transitionTime + dayNightTime

-- Storage --
local effectCount = 0

-- Tweens --
local startRainTweens = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=rainAtmosphere.Density, 
		Offset=rainAtmosphere.Offset, 
		Color=rainAtmosphere.Color,
		Decay=rainAtmosphere.Decay, 
		Glare=rainAtmosphere.Glare, 
		Haze=rainAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=rainColorCorrection.Brightness,
		Contrast=rainColorCorrection.Contrast,
		Saturation=rainColorCorrection.Saturation,
		TintColor=rainColorCorrection.TintColor,
	}),
	tweenService:Create(rainSoundEffect, defaultTween, {
		Volume=rainSoundEffect.Volume,
		PlaybackSpeed=rainSoundEffect.PlaybackSpeed,
	})
}

local startFogTween = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=fogAtmosphere.Density, 
		Offset=fogAtmosphere.Offset, 
		Color=fogAtmosphere.Color,
		Decay=fogAtmosphere.Decay, 
		Glare=fogAtmosphere.Glare, 
		Haze=fogAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=fogColorCorrection.Brightness,
		Contrast=fogColorCorrection.Contrast,
		Saturation=fogColorCorrection.Saturation,
		TintColor=fogColorCorrection.TintColor,
	}),
	tweenService:Create(depthOfField, defaultTween, {
		FarIntensity=fogDepthOfField.FarIntensity,
		FocusDistance=fogDepthOfField.FocusDistance,
		InFocusRadius=fogDepthOfField.InFocusRadius,
		NearIntensity=fogDepthOfField.NearIntensity,
	}),
	tweenService:Create(lighting, defaultTween, {
		ExposureCompensation=-0.2,
	})
}

local startDeadlySunlightTween = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=harshSunlightAtmosphere.Density, 
		Offset=harshSunlightAtmosphere.Offset, 
		Color=harshSunlightAtmosphere.Color,
		Decay=harshSunlightAtmosphere.Decay, 
		Glare=harshSunlightAtmosphere.Glare, 
		Haze=harshSunlightAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=harshSunlightColorCorrection.Brightness,
		Contrast=harshSunlightColorCorrection.Contrast,
		Saturation=harshSunlightColorCorrection.Saturation,
		TintColor=harshSunlightColorCorrection.TintColor,
	}),
	tweenService:Create(blur, defaultTween, {
		Size=harshSunlightBlur.Size,
	}),
	tweenService:Create(lighting, defaultTween, {
		ExposureCompensation=1,
	})
}

local deadlySunlightPulseTweenIn = {
	tweenService:Create(lighting, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		ExposureCompensation=3,
	})
}

local deadlySunlightPulseTweenOut = {
	tweenService:Create(lighting, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		ExposureCompensation=1,
	})
}

local bloodlustDeadlySunlightPulseTweenIn = {
	tweenService:Create(lighting, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		ExposureCompensation=2.5,
	})
}

local bloodlustDeadlySunlightPulseTweenOut = {
	tweenService:Create(lighting, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		ExposureCompensation=1,
	})
}

local startBloodlustTween = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=bloodlustAtmosphere.Density, 
		Offset=bloodlustAtmosphere.Offset, 
		Color=bloodlustAtmosphere.Color,
		Decay=bloodlustAtmosphere.Decay, 
		Glare=bloodlustAtmosphere.Glare, 
		Haze=bloodlustAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=bloodlustCorrection.Brightness,
		Contrast=bloodlustCorrection.Contrast,
		Saturation=bloodlustCorrection.Saturation,
		TintColor=bloodlustCorrection.TintColor,
	}),
	tweenService:Create(lighting, defaultTween, {
		ExposureCompensation=1,
	})
}

-- Night --
local newMoonTweens = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=newMoonAtmosphere.Density, 
		Offset=newMoonAtmosphere.Offset, 
		Color=newMoonAtmosphere.Color,
		Decay=newMoonAtmosphere.Decay, 
		Glare=newMoonAtmosphere.Glare, 
		Haze=newMoonAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=newMoonContrast.Brightness,
		Contrast=newMoonContrast.Contrast,
		Saturation=newMoonContrast.Saturation,
		TintColor=newMoonContrast.TintColor,
	}),
}

local fullMoonTweens = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=fullMoonAtmosphere.Density, 
		Offset=fullMoonAtmosphere.Offset, 
		Color=fullMoonAtmosphere.Color,
		Decay=fullMoonAtmosphere.Decay, 
		Glare=fullMoonAtmosphere.Glare, 
		Haze=fullMoonAtmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=fullMoonContrast.Brightness,
		Contrast=fullMoonContrast.Contrast,
		Saturation=fullMoonContrast.Saturation,
		TintColor=fullMoonContrast.TintColor,
	}),
	tweenService:Create(lighting, defaultTween, {
		ExposureCompensation=1.8,
	})
}

local defaultTweens = {
	tweenService:Create(atmosphere, defaultTween, {
		Density=atmosphere.Density, 
		Offset=atmosphere.Offset, 
		Color=atmosphere.Color,
		Decay=atmosphere.Decay, 
		Glare=atmosphere.Glare, 
		Haze=atmosphere.Haze, 
	}),
	tweenService:Create(colorCorrection, defaultTween, {
		Brightness=colorCorrection.Brightness,
		Contrast=colorCorrection.Contrast,
		Saturation=colorCorrection.Saturation,
		TintColor=colorCorrection.TintColor,
	}),
	tweenService:Create(depthOfField, defaultTween, {
		FarIntensity=depthOfField.FarIntensity,
		FocusDistance=depthOfField.FocusDistance,
		InFocusRadius=depthOfField.InFocusRadius,
		NearIntensity=depthOfField.NearIntensity,
	}),
	tweenService:Create(blur, defaultTween, {
		Size=blur.Size,
	}),
	tweenService:Create(lighting, defaultTween, {
		ExposureCompensation=lighting.ExposureCompensation,
	}),
	tweenService:Create(rainSoundEffect, defaultTween, {
		Volume=0,
		PlaybackSpeed=0,
	})
}

-- Functions --
local function loadTweens(tweenArray : {Tween}) 
	for _, tween in ipairs(tweenArray) do
		tween:Play()
	end
end

local function startRain()
	
	-- Prevent overrides during bloodlust.
	if bloodlustActive.Value then
		return
	end
	
	-- Start the SFX.
	rainSoundEffect:Play()

	-- Increment the effect count.
	effectCount += 1
	
	-- Tween the effect in --
	loadTweens(startRainTweens)
	
	-- Keep the effect active for a while --
	task.wait(baseDuration)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end
	
	-- Stop the rain
	rainSoundEffect:Stop()
end

local function startFog()

	-- Prevent overrides during bloodlust.
	if bloodlustActive.Value then
		return
	end
	
	-- Increment the effect count.
	effectCount += 1
	
	-- Tween the effect in --
	loadTweens(startFogTween)

	-- Keep the effect active for a while --
	task.wait(baseDuration)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end
end

local function startDeadlySunlight()

	-- Prevent overrides during bloodlust.
	if bloodlustActive.Value then
		return
	end

	-- Increment the effect count.
	effectCount += 1
	
	-- Tween the effect in --
	loadTweens(startDeadlySunlightTween)
	
	-- Keep the effect active for a while --
	task.wait(baseDuration)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end
end

local function deadlySunlightPulse()
	
	-- Prevent overrides during bloodlust.
	if bloodlustActive.Value then
		
		-- Pulse the lights brigter.
		loadTweens(bloodlustDeadlySunlightPulseTweenIn)

		task.wait(6.5)

		-- Pulse the lights brigter.
		loadTweens(bloodlustDeadlySunlightPulseTweenOut)
		return
	end
	
	-- Pulse the lights brigter.
	loadTweens(deadlySunlightPulseTweenIn)
	
	task.wait(5)
	
	-- Pulse the lights brigter.
	loadTweens(deadlySunlightPulseTweenOut)
end

local function startBloodlust()

	-- Tween the effect in --
	loadTweens(startBloodlustTween)

	-- Increment the effect count.
	effectCount += 1
	
	-- Keep the effect active for a while --
	task.wait(baseDuration * 2)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end
end

local function startFullMoon()

	-- Prevent overrides during bloodlust.
	if bloodlustActive.Value then
		return
	end

	-- Increment the effect count.
	effectCount += 1
	
	-- Tween the effect in --
	loadTweens(fullMoonTweens)
	
	-- Keep the effect active for a while --
	task.wait(baseDuration)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end

end

local function startNewMoon()

	-- Tween the effect in --
	loadTweens(newMoonTweens)

	-- Increment the effect count.
	effectCount += 1
	
	-- Keep the effect active for a while --
	task.wait(baseDuration)

	-- Increment the effect count.
	effectCount -= 1
	
	-- Tween the effect out --
	if effectCount <= 0 then
		loadTweens(defaultTweens)
		task.wait(defaultTween.Time)
	end
end

-- Events --
RAIN_EVENT.Event:Connect(startRain)
FOG_EVENT.Event:Connect(startFog)
DEADLY_SUNLIGHT_EVENT.Event:Connect(startDeadlySunlight)
NEW_MOON_EVENT.Event:Connect(startNewMoon)
FULL_MOON_EVENT.Event:Connect(startFullMoon)
BLOODLUST_EVENT.Event:Connect(startBloodlust)
deadlySunlightPulseEvent.Event:Connect(deadlySunlightPulse)